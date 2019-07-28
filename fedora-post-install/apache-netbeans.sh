#!/usr/bin/env bash

PACKAGE_POOL="/usr/local"

VERSION='11.0'

DOWNLOAD_EU_URL="https://www-eu.apache.org/dist/incubator/netbeans/incubating-netbeans/incubating-${VERSION}/incubating-netbeans-${VERSION}-bin.zip"
DOWNLOAD_US_URL="https://www-us.apache.org/dist/incubator/netbeans/incubating-netbeans/incubating-${VERSION}/incubating-netbeans-${VERSION}-bin.zip"

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

REQUIREMENTS=('wget' 'grep' 'unzip')

# Check for requirements and install them if necessary.
for REQUIREMENT in ${REQUIREMENTS}; do
    which ${REQUIREMENT} 1> /dev/null 2>&1
    [[ "${?}" == '0' ]] || dnf install -y ${REQUIREMENT}
done

# Download Apache NetBeans archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/apache-netbeans-${TMP_DATE}.zip"
TMP_PATH="/tmp/apache-netbeans-${TMP_DATE}"

wget "${DOWNLOAD_EU_URL}" -O "${TMP_FILE}"

if [[ "${?}" != '0' ]]; then
    wget "${DOWNLOAD_US_URL}" -O "${TMP_FILE}"
fi

if [[ "${?}" != '0' ]]; then
    echo '> Unable to download required files, exiting.'
    exit 1
fi

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
unzip -q "${TMP_FILE}" -d "${TMP_PATH}"

# Copy files.
cp -r "${TMP_PATH}/"* "${PACKAGE_POOL}/share/"

for BINARY in $(find "${PACKAGE_POOL}/share/netbeans/bin" -maxdepth 1 -type f -executable)
do
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/$(basename ${BINARY})"
done

# Create desktop entry for application.
if [[ ! -f "${PACKAGE_POOL}/share/applications/apache-netbeans.desktop" ]]; then
    cat > "${PACKAGE_POOL}/share/applications/apache-netbeans.desktop" <<EOL
[Desktop Entry]
Version=${VERSION}
Name=NetBeans
Comment=Integrated Development Environment
Exec=netbeans
Icon=netbeans
Categories=Development;IDE;Java;
Terminal=false
Type=Application
Keywords=development;Java;IDE;platform;javafx;javase;
StartupWMClass=NetBeans IDE ${VERSION}
EOL
fi

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished it's job.
echo '> Finished.'

