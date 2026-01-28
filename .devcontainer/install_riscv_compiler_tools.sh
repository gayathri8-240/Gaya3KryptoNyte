#!/bin/bash

#######################################
# Native RISC-V Toolchain, Spike, and PK Builder
# For KryptoNyte RISC-V Processor Family
# Builds everything from source for maximum compatibility
#######################################

# Script configuration
USE_SUDO=false
VERBOSE=true
UPGRADE_MODE=false
INSTALL_PREFIX="/opt/riscv"
BUILD_DIR="/tmp/riscv-build"
JOBS=$(nproc)

# Component versions
TOOLCHAIN_VERSION="2024.02.02"  # Stable release
SPIKE_VERSION="master"
PK_VERSION="master"

# Build configuration
BUILD_TOOLCHAIN=true
BUILD_SPIKE=true
BUILD_PK=true
CLEAN_BUILD=false

# Installation status tracking
TOOLCHAIN_BUILT=false
SPIKE_BUILT=false
PK_BUILT=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-sudo)
            USE_SUDO=true
            shift
            ;;
        --quiet)
            VERBOSE=false
            shift
            ;;
        --upgrade)
            UPGRADE_MODE=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --jobs)
            JOBS="$2"
            shift 2
            ;;
        --toolchain-version)
            TOOLCHAIN_VERSION="$2"
            shift 2
            ;;
        --spike-version)
            SPIKE_VERSION="$2"
            shift 2
            ;;
        --pk-version)
            PK_VERSION="$2"
            shift 2
            ;;
        --no-toolchain)
            BUILD_TOOLCHAIN=false
            shift
            ;;
        --no-spike)
            BUILD_SPIKE=false
            shift
            ;;
        --no-pk)
            BUILD_PK=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Native RISC-V Toolchain, Spike, and PK Builder for KryptoNyte"
            echo ""
            echo "Options:"
            echo "  --with-sudo              Use sudo for commands requiring elevated privileges"
            echo "  --quiet                  Reduce output verbosity"
            echo "  --upgrade                Force rebuild of existing components"
            echo "  --clean                  Clean build directories before building"
            echo "  --prefix DIR             Installation prefix (default: /opt/riscv)"
            echo "  --build-dir DIR          Build directory (default: /tmp/riscv-build)"
            echo "  --jobs N                 Number of parallel jobs (default: $(nproc))"
            echo "  --toolchain-version V    RISC-V toolchain version (default: 2024.02.02)"
            echo "  --spike-version V        Spike simulator version (default: master)"
            echo "  --pk-version V           Proxy kernel version (default: master)"
            echo "  --no-toolchain           Skip toolchain build"
            echo "  --no-spike               Skip Spike build"
            echo "  --no-pk                  Skip PK build"
            echo "  --help, -h               Show this help message"
            echo ""
            echo "This script builds from source:"
            echo "  - RISC-V GNU Toolchain (GCC, Binutils, Newlib)"
            echo "  - Spike RISC-V ISA Simulator"
            echo "  - RISC-V Proxy Kernel (pk)"
            echo ""
            echo "Build time: ~30-60 minutes depending on system performance"
            echo "Disk space required: ~5GB for build, ~2GB for installation"
            echo ""
            echo "Examples:"
            echo "  Build everything:"
            echo "    $0 --with-sudo"
            echo ""
            echo "  Build with custom prefix:"
            echo "    $0 --with-sudo --prefix /usr/local/riscv"
            echo ""
            echo "  Rebuild everything:"
            echo "    $0 --with-sudo --upgrade --clean"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to execute commands with optional sudo
run_cmd() {
    if [ "$USE_SUDO" = true ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Function to print large banner messages
print_banner() {
    local message="$1"
    local color="$2"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "\n${color}"
        echo "=================================================================="
        echo "  $message"
        echo "=================================================================="
        echo -e "${NC}"
    fi
}

# Function to print step messages
print_step() {
    local message="$1"
    local color="${2:-$CYAN}"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "\n${color}▶ $message${NC}"
    fi
}

# Function to print success messages
print_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
}

# Function to print error messages
print_error() {
    local message="$1"
    echo -e "${RED}✗ Error: $message${NC}" >&2
}

# Function to print warning messages
print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ Warning: $message${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_step "Checking system requirements for native RISC-V toolchain build"
    
    # Install all required dependencies upfront if using sudo
    if [ "$USE_SUDO" = true ]; then
        print_step "Installing build dependencies"
        
        sudo apt-get update
        
        print_step "Installing essential build tools"
        sudo apt-get install -y \
            build-essential git make gcc g++ autoconf automake autotools-dev cmake ninja-build \
            pkg-config curl wget unzip tar gzip
        
        print_step "Installing toolchain build dependencies"
        sudo apt-get install -y \
            libmpc-dev libmpfr-dev libgmp-dev zlib1g-dev libexpat1-dev libglib2.0-dev \
            libncurses-dev libssl-dev
        
        print_step "Installing additional build utilities"
        sudo apt-get install -y \
            gawk bison flex texinfo gperf libtool patchutils bc m4 device-tree-compiler \
            python3 python3-dev python3-pip
        
        print_success "All build dependencies installed"
    fi
    
    # Verify critical build tools
    print_step "Verifying build environment"
    
    local missing_tools=()
    
    for tool in git make gcc g++ autoconf cmake python3; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        if [ "$USE_SUDO" = false ]; then
            print_error "Run with --with-sudo to automatically install dependencies"
        fi
        exit 1
    fi
    
    # Check disk space (need ~5GB for build)
    local available_space=$(df "$BUILD_DIR" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    if [ "$available_space" -lt 5000000 ]; then  # 5GB in KB
        print_warning "Low disk space detected. Build may fail if space runs out."
        print_warning "Recommended: At least 5GB free space in $BUILD_DIR"
    fi
    
    print_success "Build environment verified"
}

# Function to setup build environment
setup_build_env() {
    print_step "Setting up build environment"
    
    # Create build directory
    if [ "$CLEAN_BUILD" = true ] || [ "$UPGRADE_MODE" = true ]; then
        print_step "Cleaning build directory"
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Create install directory
    if [ "$UPGRADE_MODE" = true ]; then
        print_step "Upgrade mode: Cleaning installation directory"
        run_cmd rm -rf "$INSTALL_PREFIX"
    fi
    
    run_cmd mkdir -p "$INSTALL_PREFIX"
    
    # Fix ownership if using sudo
    if [ "$USE_SUDO" = true ]; then
        sudo chown -R $USER:$USER "$INSTALL_PREFIX" 2>/dev/null || true
    fi
    
    # Set environment variables for build
    export PATH="$INSTALL_PREFIX/bin:$PATH"
    export RISCV="$INSTALL_PREFIX"
    
    print_success "Build environment ready"
    print_step "Build directory: $BUILD_DIR"
    print_step "Install prefix: $INSTALL_PREFIX"
    print_step "Parallel jobs: $JOBS"
}

# Function to build RISC-V toolchain
build_toolchain() {
    if [ "$BUILD_TOOLCHAIN" = false ]; then
        print_step "Skipping RISC-V toolchain build"
        return 0
    fi
    
    print_banner "Building RISC-V GNU Toolchain" "$BLUE"
    
    local toolchain_dir="$BUILD_DIR/riscv-gnu-toolchain"
    
    # Check if already built
    if [ "$UPGRADE_MODE" = false ] && [ -f "$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" ]; then
        print_success "RISC-V toolchain already built - skipping"
        TOOLCHAIN_BUILT=true
        return 0
    fi
    
    print_step "Cloning RISC-V GNU toolchain repository"
    if [ -d "$toolchain_dir" ]; then
        cd "$toolchain_dir"
        git fetch origin
        git checkout "$TOOLCHAIN_VERSION" 2>/dev/null || git checkout master
        git pull origin HEAD
    else
        git clone --recursive https://github.com/riscv-collab/riscv-gnu-toolchain.git "$toolchain_dir"
        cd "$toolchain_dir"
        git checkout "$TOOLCHAIN_VERSION" 2>/dev/null || echo "Using master branch"
    fi
    
    print_step "Updating submodules"
    git submodule update --init --recursive
    
    print_step "Configuring RISC-V toolchain build"
    # Build both 32-bit and 64-bit toolchains with multilib support
    ./configure --prefix="$INSTALL_PREFIX" --enable-multilib
    
    print_step "Building RISC-V toolchain (this will take 20-40 minutes)"
    print_step "Building with $JOBS parallel jobs"
    
    # Build the toolchain
    if make -j"$JOBS"; then
        TOOLCHAIN_BUILT=true
        print_success "RISC-V toolchain built successfully"
        
        # Verify installation
        if [ -f "$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" ]; then
            local version=$("$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" --version | head -1)
            print_success "Toolchain version: $version"
        fi
    else
        print_error "RISC-V toolchain build failed"
        return 1
    fi
}

# Function to build Spike simulator
build_spike() {
    if [ "$BUILD_SPIKE" = false ]; then
        print_step "Skipping Spike simulator build"
        return 0
    fi
    
    print_banner "Building Spike RISC-V ISA Simulator" "$YELLOW"
    
    local spike_dir="$BUILD_DIR/riscv-isa-sim"
    
    # Check if already built
    if [ "$UPGRADE_MODE" = false ] && [ -f "$INSTALL_PREFIX/bin/spike" ]; then
        print_success "Spike simulator already built - skipping"
        SPIKE_BUILT=true
        return 0
    fi
    
    print_step "Cloning Spike repository"
    if [ -d "$spike_dir" ]; then
        cd "$spike_dir"
        git fetch origin
        git checkout "$SPIKE_VERSION"
        git pull origin "$SPIKE_VERSION"
    else
        git clone --depth 1 --branch "$SPIKE_VERSION" \
            https://github.com/riscv-software-src/riscv-isa-sim.git "$spike_dir"
        cd "$spike_dir"
    fi
    
    print_step "Building Spike simulator"
    rm -rf build
    mkdir -p build
    cd build
    
    ../configure --prefix="$INSTALL_PREFIX"
    if make -j"$JOBS" && run_cmd make install; then
        SPIKE_BUILT=true
        print_success "Spike simulator built successfully"
        
        # Verify installation
        if [ -f "$INSTALL_PREFIX/bin/spike" ]; then
            print_success "Spike installed at: $INSTALL_PREFIX/bin/spike"
        fi
    else
        print_error "Spike simulator build failed"
        return 1
    fi
}

# Function to build proxy kernel
build_pk() {
    if [ "$BUILD_PK" = false ]; then
        print_step "Skipping proxy kernel build"
        return 0
    fi
    
    print_banner "Building RISC-V Proxy Kernel" "$GREEN"
    
    local pk_dir="$BUILD_DIR/riscv-pk"
    
    # Check if already built
    if [ "$UPGRADE_MODE" = false ] && [ -f "$INSTALL_PREFIX/bin/pk" ]; then
        print_success "Proxy kernel already built - skipping"
        PK_BUILT=true
        return 0
    fi
    
    # Ensure toolchain is available
    if [ ! -f "$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" ]; then
        print_error "RISC-V toolchain not found. Build toolchain first."
        return 1
    fi
    
    print_step "Cloning proxy kernel repository"
    if [ -d "$pk_dir" ]; then
        cd "$pk_dir"
        git fetch origin
        git checkout "$PK_VERSION"
        git pull origin "$PK_VERSION"
    else
        git clone --depth 1 --branch "$PK_VERSION" \
            https://github.com/riscv-software-src/riscv-pk.git "$pk_dir"
        cd "$pk_dir"
    fi
    
    print_step "Building proxy kernel"
    
    # Clean any previous build attempts
    if [ "$UPGRADE_MODE" = true ] || [ -d "build" ]; then
        print_step "Cleaning previous PK build"
        rm -rf build
        make clean 2>/dev/null || true
        make distclean 2>/dev/null || true
    fi
    
    mkdir -p build
    cd build
    
    # Set up cross-compilation environment
    export CC="$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc"
    export CXX="$INSTALL_PREFIX/bin/riscv64-unknown-elf-g++"
    export AR="$INSTALL_PREFIX/bin/riscv64-unknown-elf-ar"
    export RANLIB="$INSTALL_PREFIX/bin/riscv64-unknown-elf-ranlib"
    export STRIP="$INSTALL_PREFIX/bin/riscv64-unknown-elf-strip"
    
    print_step "Using toolchain: $CC"
    
    # Configure and build with proper ISA extensions
    # Install directly to /opt/riscv/bin like Spike
    export CFLAGS="-march=rv64imac_zicsr_zifencei -mabi=lp64"
    export CXXFLAGS="-march=rv64imac_zicsr_zifencei -mabi=lp64"
    ../configure --prefix="$INSTALL_PREFIX" --host=riscv64-unknown-elf --with-arch=rv64imac_zicsr_zifencei
    if make -j"$JOBS" && run_cmd make install; then
        # Copy pk binary to main bin directory for consistency with Spike
        if [ -f "$INSTALL_PREFIX/riscv64-unknown-elf/bin/pk" ]; then
            print_step "Copying PK to main bin directory"
            run_cmd cp "$INSTALL_PREFIX/riscv64-unknown-elf/bin/pk" "$INSTALL_PREFIX/bin/pk"
            run_cmd cp "$INSTALL_PREFIX/riscv64-unknown-elf/bin/bbl" "$INSTALL_PREFIX/bin/bbl" 2>/dev/null || true
        fi
        
        PK_BUILT=true
        print_success "Proxy kernel built successfully"
        
        # Verify installation
        if [ -f "$INSTALL_PREFIX/bin/pk" ]; then
            print_success "Proxy kernel installed at: $INSTALL_PREFIX/bin/pk"
        else
            print_warning "PK built but not found at expected location"
        fi
    else
        print_error "Proxy kernel build failed"
        return 1
    fi
    
    # Reset environment variables
    unset CC CXX AR RANLIB STRIP
}

# Function to setup environment
setup_environment() {
    print_banner "Setting up environment" "$PURPLE"
    
    local env_file="$HOME/.riscv_native_env"
    
    print_step "Creating environment configuration file"
    cat > "$env_file" << EOF
# Native RISC-V Toolchain Environment Variables
# Source this file or add to your shell profile (.bashrc, .zshrc, etc.)

# RISC-V Installation
export RISCV="$INSTALL_PREFIX"
export RISCV_TOOLCHAIN_ROOT="$INSTALL_PREFIX"

# Add RISC-V tools to PATH
export PATH="$INSTALL_PREFIX/bin:\$PATH"

# RISC-V specific environment
export RISCV_PREFIX="riscv64-unknown-elf-"

# Tool locations
export SPIKE_ROOT="$INSTALL_PREFIX"
export PK_ROOT="$INSTALL_PREFIX"

echo "Native RISC-V toolchain environment loaded"
echo "Toolchain: $INSTALL_PREFIX"
echo "Tools available: \$(ls $INSTALL_PREFIX/bin/riscv* 2>/dev/null | wc -l) RISC-V tools"
EOF

    print_step "Environment file created at: $env_file"
    
    # Add to shell profile if possible
    local shell_profile=""
    if [ -n "$BASH_VERSION" ]; then
        shell_profile="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_profile="$HOME/.zshrc"
    fi
    
    if [ -n "$shell_profile" ] && [ -w "$shell_profile" ]; then
        if ! grep -q "riscv_native_env" "$shell_profile"; then
            print_step "Adding environment setup to $shell_profile"
            echo "" >> "$shell_profile"
            echo "# Native RISC-V Toolchain Environment" >> "$shell_profile"
            echo "source $env_file" >> "$shell_profile"
            print_success "Environment setup added to shell profile"
        fi
    fi
    
    print_success "Environment configuration complete"
    
    echo -e "\n${CYAN}To use the native RISC-V toolchain in your current session, run:${NC}"
    echo -e "${WHITE}source $env_file${NC}"
}

# Function to verify installation
verify_installation() {
    print_banner "Verifying installation" "$GREEN"
    
    local errors=0
    local warnings=0
    
    # Check toolchain
    if [ "$BUILD_TOOLCHAIN" = true ]; then
        if [ "$TOOLCHAIN_BUILT" = true ] && [ -f "$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" ]; then
            print_success "RISC-V toolchain built and installed successfully"
            local version=$("$INSTALL_PREFIX/bin/riscv64-unknown-elf-gcc" --version | head -1)
            print_step "Toolchain: $version"
        else
            print_error "RISC-V toolchain build failed"
            ((errors++))
        fi
    fi
    
    # Check Spike
    if [ "$BUILD_SPIKE" = true ]; then
        if [ "$SPIKE_BUILT" = true ] && [ -f "$INSTALL_PREFIX/bin/spike" ]; then
            print_success "Spike simulator built and installed successfully"
        else
            print_error "Spike simulator build failed"
            ((errors++))
        fi
    fi
    
    # Check PK
    if [ "$BUILD_PK" = true ]; then
        if [ "$PK_BUILT" = true ] && [ -f "$INSTALL_PREFIX/bin/pk" ]; then
            print_success "Proxy kernel built and installed successfully"
        else
            print_error "Proxy kernel build failed"
            ((errors++))
        fi
    fi
    
    if [ $errors -eq 0 ]; then
        print_banner "Build completed successfully!" "$GREEN"
        echo -e "\n${GREEN}✅ All components built successfully!${NC}"
        
        echo -e "\n${CYAN}📋 Installation Summary:${NC}"
        [ "$BUILD_TOOLCHAIN" = true ] && [ "$TOOLCHAIN_BUILT" = true ] && echo -e "  🛠️  RISC-V Toolchain: ${GREEN}✅ Built${NC}"
        [ "$BUILD_SPIKE" = true ] && [ "$SPIKE_BUILT" = true ] && echo -e "  🔧 Spike Simulator: ${GREEN}✅ Built${NC}"
        [ "$BUILD_PK" = true ] && [ "$PK_BUILT" = true ] && echo -e "  ⚙️  Proxy Kernel: ${GREEN}✅ Built${NC}"
        
        echo -e "\n${CYAN}📁 Installation Location:${NC}"
        echo -e "  📂 Install Prefix: ${WHITE}$INSTALL_PREFIX${NC}"
        echo -e "  🌍 Environment File: ${WHITE}$HOME/.riscv_native_env${NC}"
        
        echo -e "\n${CYAN}🚀 Next Steps:${NC}"
        echo -e "  1. Load environment: ${WHITE}source ~/.riscv_native_env${NC}"
        echo -e "  2. Test toolchain: ${WHITE}riscv64-unknown-elf-gcc --version${NC}"
        echo -e "  3. Test Spike: ${WHITE}spike --help${NC}"
        echo -e "  4. Use with KryptoNyte conformance tests"
        
        # Clean up build directory if successful
        if [ "$CLEAN_BUILD" = true ]; then
            print_step "Cleaning up build directory"
            rm -rf "$BUILD_DIR"
            print_success "Build directory cleaned"
        fi
        
    else
        print_banner "Build failed" "$RED"
        echo -e "\n${RED}❌ Build failed with $errors component failures${NC}"
        echo -e "\n${CYAN}🔧 Troubleshooting:${NC}"
        echo -e "  1. Check build logs above for specific errors"
        echo -e "  2. Ensure sufficient disk space (~5GB)"
        echo -e "  3. Verify all dependencies are installed"
        echo -e "  4. Try with --clean flag to force clean build"
        echo -e "  5. Check network connectivity for repository access"
        exit 1
    fi
}

# Main build flow
main() {
    print_banner "Native RISC-V Toolchain Builder for KryptoNyte" "$BLUE"
    
    echo -e "${CYAN}Build Configuration:${NC}"
    echo -e "  Install Prefix: ${WHITE}$INSTALL_PREFIX${NC}"
    echo -e "  Build Directory: ${WHITE}$BUILD_DIR${NC}"
    echo -e "  Parallel Jobs: ${WHITE}$JOBS${NC}"
    echo -e "  Build Toolchain: ${WHITE}$BUILD_TOOLCHAIN${NC}"
    echo -e "  Build Spike: ${WHITE}$BUILD_SPIKE${NC}"
    echo -e "  Build PK: ${WHITE}$BUILD_PK${NC}"
    echo -e "  Use Sudo: ${WHITE}$USE_SUDO${NC}"
    echo -e "  Upgrade Mode: ${WHITE}$UPGRADE_MODE${NC}"
    echo -e "  Clean Build: ${WHITE}$CLEAN_BUILD${NC}"
    
    # Estimate build time
    local estimated_time="20-40 minutes"
    if [ "$BUILD_TOOLCHAIN" = false ]; then
        estimated_time="5-10 minutes"
    fi
    
    echo -e "\n${YELLOW}⏱️  Estimated build time: $estimated_time${NC}"
    echo -e "${YELLOW}💾 Disk space required: ~5GB for build, ~2GB for installation${NC}"
    
    # Confirm build
    if [ "$VERBOSE" = true ]; then
        echo ""
        read -p "Continue with native build? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_error "Build cancelled by user"
            exit 1
        fi
    fi
    
    check_requirements
    setup_build_env
    build_toolchain
    build_spike
    build_pk
    setup_environment
    verify_installation
    
    print_banner "Native RISC-V Build Complete!" "$GREEN"
}

# Ensure terminal is reset even if script is interrupted
trap 'echo -e "\033[0m"; stty echo' EXIT INT TERM

# Run main function
main "$@"
