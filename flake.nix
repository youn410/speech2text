{
  description = "Transcribe audio to text with Whisper.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          python = pkgs.python311;
        in {
          default = pkgs.mkShell {
            packages = [
              python
              python.pkgs.pip
              python.pkgs.setuptools
              python.pkgs.wheel
              pkgs.ffmpeg
            ];

            shellHook = ''
              set -euo pipefail

              export PIP_PREFIX="$(pwd)/.venv"
              export PATH="$PIP_PREFIX/bin:$PATH"
              export PYTHONPATH="$PIP_PREFIX/lib/python3.11/site-packages:$PYTHONPATH"
              export XDG_CACHE_HOME="$(pwd)/.cache"
              export PIP_DISABLE_PIP_VERSION_CHECK=1

              mkdir -p "$PIP_PREFIX"

              if [ ! -f "$PIP_PREFIX/.installed" ]; then
                echo "📦 Installing Python packages into $PIP_PREFIX ..."

                OS="$(uname -s)"; ARCH="$(uname -m)"

                # Use Torch 2.2.x universally (wheels available for macOS Intel/ARM & Linux CPU)
                if [ "$OS" = "Darwin" ]; then
                  # macOS (both arm64 & x86_64)
                  python -m pip install --prefix "$PIP_PREFIX" "numpy==1.26.4" 
                  python -m pip install --prefix "$PIP_PREFIX" \
                    torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2
                else
                  # Linux CPU wheels from official index
                  python -m pip install --prefix "$PIP_PREFIX" "numpy==1.26.4" 
                  python -m pip install --prefix "$PIP_PREFIX" \
                    torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2 \
                    --index-url https://download.pytorch.org/whl/cpu
                fi

                # Whisper CLI
                python -m pip install --prefix "$PIP_PREFIX" "openai-whisper>=20231117"

                touch "$PIP_PREFIX/.installed"
                echo "✅ Done."
              fi

              echo "🐍 Whisper CLI devShell ready. Try: whisper --help"
            '';
          };
        });
    };
}
