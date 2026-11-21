#include "QwCore.h"
#include "sc_core.h"
#include "stb/stb_image.h"
#include "stb/stb_image_write.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>
#include <string>
#include <unistd.h>

static void check(bool ok, const std::string& message) {
    if (!ok) throw std::runtime_error(message);
}
static std::string run(const char* name, const std::vector<std::string>& args) {
    std::vector<const char*> pointers;
    for (auto& a : args) pointers.push_back(a.c_str());
    char* value = qw_run(name, (int)pointers.size(), pointers.data());
    check(value != nullptr, "Null native result");
    std::string result(value); qw_free(value);
    return result;
}
static std::string success(const char* name, const std::vector<std::string>& args) {
    auto result = run(name, args);
    check(result.find("Error") != 0 && result.find("❌") != 0, std::string(name) + ": " + result);
    return result;
}
int main() {
    namespace fs = std::filesystem;
    fs::path dir = fs::temp_directory_path() / ("qwsc-tests-" + std::to_string(getpid()));
    try {
        fs::create_directories(dir / "decoded");
        const std::string out = dir.string(), decoded = (dir / "decoded").string();
        const std::vector<uint8_t> payload = {1,2,3,4,0,255,7,9,11,0,0,0};
        for (auto kind : {CompKind::ZSTD, CompKind::ZLIB}) {
            auto compressed = sc_compress(payload, kind);
            check(sc_decompress(compressed, {0, kind}) == payload, "Compression roundtrip failed");
        }
        std::vector<unsigned char> pixels(16 * 16 * 4);
        for (size_t i = 0; i < pixels.size(); i += 4) { pixels[i] = 70; pixels[i+1] = 140; pixels[i+2] = 210; pixels[i+3] = 255; }
        std::string png = (dir / "fixture.png").string();
        check(stbi_write_png(png.c_str(), 16, 16, 4, pixels.data(), 64) != 0, "PNG fixture creation failed");
        success("nativePng2Ktx", {png, "8x8", out});
        check(fs::file_size(dir / "fixture.ktx") > 64, "KTX was not written");
        success("nativeKtx2Png", {(dir / "fixture.ktx").string(), decoded});
        int w=0,h=0,ch=0;
        auto image = stbi_load((dir / "decoded/fixture.png").c_str(), &w, &h, &ch, 4);
        check(image && w == 16 && h == 16, "Decoded KTX dimensions wrong");
        check(std::abs((int)image[0] - 70) < 20 && image[3] == 255, "Decoded KTX pixels wrong");
        stbi_image_free(image);
        success("nativePng2Sctx", {png, out});
        success("nativeSctx2Png", {(dir / "fixture.sctx").string(), decoded});
        image = stbi_load((dir / "decoded/fixture.png").c_str(), &w, &h, &ch, 4);
        check(image && w == 16 && h == 16, "Decoded SCTX dimensions wrong");
        stbi_image_free(image);
        success("nativeBuildSc", {png, "fixture", "8x8", out});
        auto sc = (dir / "fixture.sc").string();
        check(fs::exists(sc) && fs::exists(dir / "fixture_tex.sc"), "SC build outputs missing");
        auto names = success("nativeGetExports", {sc});
        check(names.find("fixture") != std::string::npos, "SC export name missing");
        auto atlas = success("nativeGetScInfo", {sc, out});
        check(fs::exists(dir / "fixture_atlas.raw"), "Editor atlas missing");
        check(atlas.find("|") != std::string::npos, "Editor sprite metadata missing: " + atlas);
        std::ofstream(dir / "ops.txt") << "R\t0\trenamed\n";
        success("nativeEditExports", {(dir / "ops.txt").string(), sc, decoded});
        bool found = false;
        for (auto& f : fs::directory_iterator(dir / "decoded")) {
            if (f.path().extension() == ".sc") {
                auto edited = success("nativeGetExports", {f.path().string()});
                check(edited.find("renamed") != std::string::npos, "Export edit did not persist");
                found = true;
            }
        }
        check(found, "Export edit output missing");
        check(run("nativeScInfo", {"/file-does-not-exist"}).find("❌") == 0, "Missing file was accepted");
        check(run("nativePng2Ktx", {png, "8x8"}).find("Error") == 0, "Wrong argument count was accepted");
        check(run("nativeSc2Png", {sc, "xyz", out}).find("Error") == 0, "Invalid number was accepted");
        check(run("unknown", {}).find("Error") == 0, "Unknown operation was accepted");
        fs::remove_all(dir);
        std::cout << "PASS: compression, PNG/KTX/SCTX roundtrips, SC build, editor atlas, exports edit, error paths\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << "\nFixtures: " << dir << '\n';
        return 1;
    }
}
