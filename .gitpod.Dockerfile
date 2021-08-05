FROM gitpod/workspace-full-vnc

ENV ANDROID_HOME=/home/gitpod/android-sdk-linux \
    ANDROID_VERSION=3.3.0.20 \
    FLUTTER_HOME=/home/gitpod/flutter \
    FLUTTER_VERSION=2.2.3-stable

USER root

# Download and install Dart
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list \
    && install-packages build-essential dart libkrb5-dev gcc make gradle android-tools-adb android-tools-fastboot

USER gitpod

# Download Flutter
RUN cd /home/gitpod \
    && wget -qO flutter_sdk.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz \
    && tar -xvf flutter_sdk.tar.xz && rm flutter_sdk.tar.xz

# Download Android Studio
RUN cd /home/gitpod \
    && wget -qO android_studio.zip https://dl.google.com/dl/android/studio/ide-zips/${ANDROID_VERSION}/android-studio-ide-182.5199772-linux.zip \
    && unzip android_studio.zip && rm -f android_studio.zip

# Setup Android Command Tools (sdkmanager)
RUN cd /home/gitpod \
    && wget -qO commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    && unzip commandlinetools.zip \
    && yes | cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses \
    && cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "build-tools;28.0.3" "platforms;android-28" \
    && cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "build-tools;29.0.2" "platforms;android-29" \
    && cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "system-images;android-30;google_apis_playstore;x86" \
    && cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --install "cmdline-tools;latest" \
    && rm commandlinetools.zip

# Web is available on master channel
RUN $FLUTTER_HOME/bin/flutter channel master && $FLUTTER_HOME/bin/flutter upgrade && $FLUTTER_HOME/bin/flutter config --enable-web

# Optional (flutter Accept licenses & DevTools)
RUN yes | $FLUTTER_HOME/bin/flutter doctor --android-licenses
RUN $FLUTTER_HOME/bin/flutter pub global activate devtools

# Change the PUB_CACHE to /workspace so dependencies are preserved.
ENV PUB_CACHE=/workspace/.pub_cache

# add executables to PATH
RUN echo 'export PATH=${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PUB_CACHE}/bin:${FLUTTER_HOME}/.pub-cache/bin:${ANDROID_HOME}/tools:$PATH' >> ~/.bashrc
