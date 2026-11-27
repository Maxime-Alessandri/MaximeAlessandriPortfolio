#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>
#include <QDir>
#include <QDebug>
#include <iostream>

static void customLogOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QByteArray localMsg = msg.toLocal8Bit();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    switch (type) {
    case QtDebugMsg:
        std::cerr << "[QML DEBUG] " << localMsg.constData() << std::endl;
        break;
    case QtInfoMsg:
        std::cerr << "[QML INFO] " << localMsg.constData() << std::endl;
        break;
    case QtWarningMsg:
        std::cerr << "[QML WARNING] " << localMsg.constData() << " (" << file << ":" << context.line << ")" << std::endl;
        break;
    case QtCriticalMsg:
        std::cerr << "[QML CRITICAL] " << localMsg.constData() << " (" << file << ":" << context.line << ")" << std::endl;
        break;
    case QtFatalMsg:
        std::cerr << "[QML FATAL] " << localMsg.constData() << " (" << file << ":" << context.line << ")" << std::endl;
        abort();
    }
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(customLogOutput);

    QGuiApplication app(argc, argv);
    app.setOrganizationName("Invenesis");
    app.setOrganizationDomain("invenesis.com");
    app.setApplicationName("MaximeAlessandriPortfolio");

    // Load and register custom embedded typography
    QStringList fontFiles = {
        ":/InvenesisPortfolio/assets/fonts/CormorantGaramond[wght].ttf",
        ":/InvenesisPortfolio/assets/fonts/CormorantGaramond-Italic[wght].ttf",
        ":/InvenesisPortfolio/assets/fonts/JetBrainsMono-Regular.ttf",
        ":/InvenesisPortfolio/assets/fonts/JetBrainsMono-Bold.ttf",
        ":/InvenesisPortfolio/assets/fonts/Inter-VariableFont.ttf",
        ":/InvenesisPortfolio/assets/fonts/Inter-Italic-VariableFont.ttf",
        ":/InvenesisPortfolio/assets/fonts/MaterialSymbolsOutlined.ttf"
    };

    for (const QString &fontPath : fontFiles) {
        int id = QFontDatabase::addApplicationFont(fontPath);
        if (id == -1) {
            QString localPath = "assets/fonts/" + QFileInfo(fontPath).fileName();
            QFontDatabase::addApplicationFont(localPath);
        }
    }

    QQmlApplicationEngine engine;

    // Explicitly add QRC root and QML module paths
    engine.addImportPath("qrc:/");
    engine.addImportPath("qrc:/qt/qml");

    // Load Master QML module entry point
    const QUrl url(QStringLiteral("qrc:/InvenesisPortfolio/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            std::cerr << "[FATAL] Failed to load root QML component: " << url.toString().toStdString() << std::endl;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
