#include "duduregiconfig.h"
#include "projectionmode.h"
#include <QVariant>
#include <QMetaType>
#include <QTime>
#include <QDebug>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <stdlib.h>
#include <QHostAddress>
#include <unistd.h>
#include <sys/types.h>


ProjectionModePrivate::ProjectionModePrivate(QObject *parent) :
    QObject(parent)
{

}

void ProjectionModePrivate::returnToNative() {
    qDebug() << __func__;
}

ProjectionMode::ProjectionMode(QObject *parent) :
    QTcpServer(parent), mMediaPlayer(0)
{
    mPM = new ProjectionModePrivate();
    new ProjectionModeAdaptor(mPM);
    QDBusConnection connection = QDBusConnection::sessionBus();
    if(getuid() == 0) {
        qDebug() << "connection to systemBus";
        connection = QDBusConnection::systemBus();
    }
    qDebug() << "register" << connection.registerObject("/AndroidAuto", mPM);
    qDebug() << "register" << connection.registerService("com.windriver.automotive.ProjectionMode");

    listen(QHostAddress(QHostAddress::LocalHost), 32323);
}
void ProjectionMode::sendMouseMove(int x, int y) {
    emit mPM->touchEvent(x, y, 2);
};
void ProjectionMode::sendMousePressed(int x, int y) {
    emit mPM->touchEvent(x, y, 1);
};
void ProjectionMode::sendKeyPressed(int keycode) {
    emit mPM->keyEvent(keycode, true);
}
void ProjectionMode::sendMouseReleased(int x, int y) {
    emit mPM->touchEvent(x, y, 0);
};
void ProjectionMode::sendKeyReleased(int keycode) {
    emit mPM->keyEvent(keycode, false);
}
void ProjectionMode::sendVideoFocus(int acquired) {
    emit mPM->focusEvent(acquired);
}

void ProjectionMode::setMediaPlayer(QObject *obj) {
    mMediaPlayer = qvariant_cast<QMediaPlayer *>(obj->property("mediaObject"));
    connect(mMediaPlayer, SIGNAL(mediaStatusChanged(QMediaPlayer::MediaStatus)), this, SLOT(slotMediaStatusChanged(QMediaPlayer::MediaStatus)));
};
void ProjectionMode::incomingConnection(qintptr socketDescriptor) {
    /*
    QFile *video = new QFile("data/androidauto.h264");
    video->open(QIODevice::ReadOnly);
    mMediaPlayer->setMedia(0, video);
    mMediaPlayer->play();
    */
    qDebug() << "incomming";
    ProjectionStream *stream = new ProjectionStream(mMediaPlayer, this);
    stream->setSocketDescriptor(socketDescriptor);
    qDebug() << "mediaStatus" << mMediaPlayer->mediaStatus();
}

void ProjectionMode::slotMediaStatusChanged(QMediaPlayer::MediaStatus status) {
    qDebug() << "mediaStatus changed to " << status;

    if(status == QMediaPlayer::LoadedMedia && QMediaPlayer::PlayingState != mMediaPlayer->state()) {
        mMediaPlayer->play();
        qDebug() << "play!";
    }
}


ProjectionStream::ProjectionStream(QMediaPlayer *player, QObject *parent) :
    QTcpSocket(parent), mMediaPlayer(player), mInit(false), mPrepareBufferLength(0)
{
    mBuffer.open(QBuffer::ReadWrite);
    QObject::connect(this, SIGNAL(disconnected()), this, SLOT(slotDisconnected()));
    QObject::connect(this, SIGNAL(readyRead()), this, SLOT(slotReadyRead()));
}

qint64 ProjectionStream::bytesAvailable() const {
    //qDebug() << "bytesAvailable ??" << QTcpSocket::bytesAvailable();
    qint64 r = QTcpSocket::bytesAvailable();
    if( r == 0 ) {
        return 1;
    }
    return r;
}

bool ProjectionStream::atEnd() const {
    return false;
}
void ProjectionStream::slotDisconnected() {
    qDebug() << "disconnected";
    mMediaPlayer->stop();
    mMediaPlayer->setMedia(0, 0);
    mPrepareBufferLength = 0;
    qDebug() << "mediaStatus" << mMediaPlayer->mediaStatus();
}

void ProjectionStream::slotReadyRead() {
    qint64 r = bytesAvailable();
    if(mPrepareBufferLength<100000)
        mPrepareBufferLength += r;
    //qDebug() << "r" << r;
    if(mPrepareBufferLength > 100000 && QMediaPlayer::PlayingState != mMediaPlayer->state() && r>0) {
        qDebug() << "mediaStatus" << mMediaPlayer->mediaStatus();
        if(QMediaPlayer::NoMedia == mMediaPlayer->mediaStatus())
            mMediaPlayer->setMedia(QMediaContent(QUrl("udp://")), this);

    }
}
