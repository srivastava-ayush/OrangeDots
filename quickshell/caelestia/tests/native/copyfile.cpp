#include "cutils.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

static void check(bool condition, const char* message) {
    if (!condition) {
        std::fprintf(stderr, "FAIL: %s\n", message);
        std::exit(1);
    }
}

static void write(const QString& path, const QByteArray& contents) {
    QFile file(path);
    check(file.open(QIODevice::WriteOnly), "open disposable file");
    check(file.write(contents) == contents.size(), "write disposable file");
}

static QByteArray read(const QString& path) {
    QFile file(path);
    check(file.open(QIODevice::ReadOnly), "destination must still exist");
    return file.readAll();
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir directory;
    check(directory.isValid(), "create disposable directory");
    const auto source = directory.filePath("source");
    const auto target = directory.filePath("target");
    const auto copy = [](const QString& from, const QString& to, bool overwrite = true) {
        return caelestia::CUtils::copyFile(QUrl::fromLocalFile(from), QUrl::fromLocalFile(to), overwrite);
    };
    write(source, "new avatar");
    write(target, "original avatar");
    check(!copy(directory.filePath("missing"), target), "missing source must fail");
    check(read(target) == "original avatar", "missing source must preserve original destination");
    check(copy(source, source), "same-file overwrite is a successful no-op");
    check(read(source) == "new avatar", "same-file overwrite must preserve contents");
    check(!copy(source, target, false), "no-overwrite must refuse an existing target");
    check(read(target) == "original avatar", "no-overwrite must preserve destination");
    check(copy(source, target), "valid overwrite");
    check(read(target) == "new avatar", "valid overwrite replaces contents");
    check(copy(source, directory.filePath("new-target")), "copy to a new destination");
    const auto link = directory.filePath("link");
    check(QFile::link(source, link), "create same-source symlink");
    check(copy(source, link) && read(source) == "new avatar", "same-file symlink must be a nondestructive no-op");
    check(QFile::remove(link) && QFile::link(target, link), "create unrelated destination symlink");
    write(target, "referent must survive");
    check(copy(source, link), "replace destination symlink");
    check(!QFileInfo(link).isSymLink() && read(link) == "new avatar", "replace link itself with copied file");
    check(read(target) == "referent must survive", "do not overwrite symlink referent");
    write(target, "new avatar");
    check(!copy(source, directory.path()), "directory destination must fail");
    check(QFileInfo(directory.path()).isDir(), "directory destination must survive failure");
    check(!caelestia::CUtils::copyFile(QUrl("https://invalid.example/file"), QUrl::fromLocalFile(target)), "reject nonlocal source");
    check(read(target) == "new avatar", "invalid URL must preserve destination");
    // A non-root writer cannot replace a file in a read-only directory. Do not
    // use this check as root, where DAC bypass would invalidate the fixture.
    if (::getuid() != 0) {
        const auto blocked = directory.filePath("blocked");
        check(QDir().mkdir(blocked), "create blocked directory");
        const auto blockedTarget = blocked + "/target";
        write(blockedTarget, "protected avatar");
        check(QFile::setPermissions(blocked, QFileDevice::ReadOwner | QFileDevice::ExeOwner), "remove directory write permission");
        const bool result = copy(source, blockedTarget);
        const auto contents = read(blockedTarget);
        check(QFile::setPermissions(blocked, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner), "restore disposable permissions");
        check(!result && contents == "protected avatar", "failed replacement must preserve destination");
    }
}
