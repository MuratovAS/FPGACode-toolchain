#!/bin/sh

TOOLCHAIN_PATH=$(readlink -f $1)
LOCAL_DIR=$(dirname $(readlink -f $0))

mkdir -p $TOOLCHAIN_PATH

echo "DEBUG: TOOLCHAIN_PATH=$TOOLCHAIN_PATH"
echo "DEBUG: LOCAL_DIR=$LOCAL_DIR"

#Download GHRD (Download GitHub release)
GHRD="/zero88/gh-release-downloader"
GHRD_VERSION=$(curl "https://github.com/$GHRD/releases/latest" -s -L -I -o /dev/null -w '%{url_effective}' | sed -n '{s@.*/@@; p}')
GHRD_FILE="https://github.com/$GHRD/releases/download/$GHRD_VERSION/ghrd"
curl -L "$GHRD_FILE" > "$TOOLCHAIN_PATH/ghrd" && chmod +x "$TOOLCHAIN_PATH/ghrd"
# patch GHRD
sudo sed -i 's@OUT=/tmp.*@OUT=/tmp/ghrd-$RANDOM.json@' $TOOLCHAIN_PATH/ghrd

#Update PATH
PATH=$(echo $TOOLCHAIN_PATH):$PATH

#Download github
githubDownload() {
	ghrd -x -a $2 $1
	if [ -n "$3" ]
	then
		mv $(find $TOOLCHAIN_PATH -regex ".*$2") $3
	fi
}

cd $TOOLCHAIN_PATH && cat $LOCAL_DIR/toolchain.txt \
										| sed '/^###external/q' | sed '/^#/d' \
										| while read line || [[ -n $line ]];
											do
												githubDownload $line
											done; \
											ls *.tar.gz | while read i; \
											do \
												rm -rf ${i%%.tar.gz}; \
												mkdir ${i%%.tar.gz}; \
												tar xvf $i -C ${i%%.tar.gz}; \
												rm $i; \
											done

#Download external
cd $TOOLCHAIN_PATH && cat $LOCAL_DIR/toolchain.txt \
									| sed '/^#/d' | grep "toolchain-sdcc" \
									&& curl -L https://sourceforge.net/projects/sdcc/files/sdcc-linux-amd64/4.0.0/sdcc-4.0.0-amd64-unknown-linux2.5.tar.bz2 > "sdcc.tar.bz2" \
									&& tar -xvf sdcc.tar.bz2 \
									&& rm sdcc.tar.bz2 \
									&& curl -L https://sourceforge.net/projects/srecord/files/srecord/1.65/srecord-1.65.0-Linux.tar.gz > "srecord.tar.gz" \
									&& tar -xvf srecord.tar.gz \
									&& rm srecord.tar.gz

#Move utils
mkdir -p $TOOLCHAIN_PATH/utils/bin && cd $TOOLCHAIN_PATH \
									&& for file in * .* 
									do
										test -f "$file" && mv -f "$file" "$TOOLCHAIN_PATH/utils/bin"/
									done

#Update vscode conf
cd $LOCAL_DIR
cat $LOCAL_DIR/toolchain.txt | sed '/^#/d' | grep "toolchain-iverilog" \
	&& if [ -d ".vscode" ]; then sed -i "s@\(\"verilog.linting.path\":\)[^,]*@\1 \"$TOOLCHAIN_PATH/toolchain-iverilog/bin/\"@" .vscode/settings.json; fi
cat $LOCAL_DIR/toolchain.txt | sed '/^#/d' | grep "toolchain-yosys" \
	&& if [ -d ".vscode" ]; then sed -i "s@\(\"verilog.linting.iverilog.arguments\":\)[^,]*@\1 \"-B $TOOLCHAIN_PATH/toolchain-iverilog/lib/ivl $TOOLCHAIN_PATH/toolchain-yosys/share/yosys/ice40/cells_sim.v src/top.v\"@" .vscode/settings.json; fi

cat $LOCAL_DIR/toolchain.txt | sed '/^#/d' | grep "tools-oss-cad-suite" \
	&& if [ -d ".vscode" ]; then sed -i "s@\(\"verilog.linting.path\":\)[^,]*@\1 \"$TOOLCHAIN_PATH/tools-oss-cad-suite/bin/\"@" .vscode/settings.json; fi
cat $LOCAL_DIR/toolchain.txt | sed '/^#/d' | grep "tools-oss-cad-suite" \
	&& if [ -d ".vscode" ]; then sed -i "s@\(\"verilog.linting.iverilog.arguments\":\)[^,]*@\1 \"-B $TOOLCHAIN_PATH/tools-oss-cad-suite/lib/ivl $TOOLCHAIN_PATH/tools-oss-cad-suite/share/yosys/ice40/cells_sim.v src/top.v\"@" .vscode/settings.json; fi

cat $LOCAL_DIR/toolchain.txt | sed '/^#/d' | grep "toolchain-sdcc" \
	&& if [ -d ".vscode" ]; then sed -i "s@[$$\"].*/sdcc-4.0.0@\"$TOOLCHAIN_PATH/sdcc-4.0.0@" .vscode/c_cpp_properties.json; fi


#Completed
echo "Installation completed"