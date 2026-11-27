#pragma once

#include <QObject>
#include <QUrl>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QtGlobal>
#include <QtQml/qqmlregistration.h>

class AppConfig : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString localAssetsDir READ localAssetsDir CONSTANT)

public:
    explicit AppConfig(QObject *parent = nullptr) : QObject(parent)
    {
#ifdef Q_OS_WASM
        // 1. Check Emscripten preloaded virtual filesystem mount
        const QString wasmAssets = QStringLiteral("/assets");
        if (QDir(wasmAssets).exists()) {
            m_localAssetsDir = wasmAssets;
            return;
        }
#endif

        // 2. Check shared Tecan CAD models directory
        const QString tecanData = QStringLiteral("C:/ProgramData/Tecan/HeroAssets");
        if (QDir(tecanData).exists()) {
            m_localAssetsDir = tecanData;
            return;
        }

        // 3. Check local application build/assets directory
        QString path = QCoreApplication::applicationDirPath() + QStringLiteral("/assets");
        if (QDir(path).exists()) {
            m_localAssetsDir = QDir::cleanPath(path);
            return;
        }

        // 4. Fallback to repository root
        path = QCoreApplication::applicationDirPath() + QStringLiteral("/..");
        m_localAssetsDir = QDir::cleanPath(path);
    }

    QString localAssetsDir() const { return m_localAssetsDir; }

    Q_INVOKABLE QUrl asset(const QString &relativePath) const
    {
        QString targetRel = relativePath;
        if (targetRel.endsWith(QStringLiteral(".gltf"), Qt::CaseInsensitive)) {
            const QString glbRel = targetRel.left(targetRel.length() - 5) + QStringLiteral(".glb");
            if (QFile::exists(m_localAssetsDir + QLatin1Char('/') + glbRel)) {
                targetRel = glbRel;
            }
        }

        const QString fullPath = m_localAssetsDir + QLatin1Char('/') + targetRel;
        if (QFile::exists(fullPath)) {
            return QUrl::fromLocalFile(fullPath);
        }

        // Fallback for packaged Qt resources
        return QUrl(QStringLiteral("qrc:/InvenesisPortfolio/assets/") + targetRel);
    }

    Q_INVOKABLE QUrl cvUrl() const
    {
#ifdef Q_OS_WASM
        return QUrl(QStringLiteral("Maxime_Alessandri_CV_Lab_Automation_V2.docx"));
#else
        const QString appDir = QCoreApplication::applicationDirPath();
        const QStringList candidates = {
            appDir + QStringLiteral("/Maxime_Alessandri_CV_Lab_Automation_V2.docx"),
            appDir + QStringLiteral("/../Maxime_Alessandri_CV_Lab_Automation_V2.docx")
        };
        for (const QString &candidate : candidates) {
            const QString cleaned = QDir::cleanPath(candidate);
            if (QFile::exists(cleaned)) {
                return QUrl::fromLocalFile(cleaned);
            }
        }
        return QUrl(QStringLiteral("Maxime_Alessandri_CV_Lab_Automation_V2.docx"));
#endif
    }

private:
    QString m_localAssetsDir;
};
