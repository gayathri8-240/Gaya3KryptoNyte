#!/bin/bash

#######################################
# RISC-V Conformance Tests Installation Script
# For KryptoNyte RISC-V Processor Family
# Includes UV Python, Spike Simulator, and Proxy Kernel
#######################################

# Script configuration
USE_SUDO=false
VERBOSE=true
UPGRADE_MODE=false
INSTALL_DIR="/opt/riscv-conformance"
ARCH_TEST_VERSION="main"  # Can be changed to specific tag/commit
SPIKE_VERSION="master"
PK_VERSION="master"

# Test suite configuration
INSTALL_SPIKE=true
INSTALL_PK=true
BUILD_TESTS=true

# Installation status tracking
UV_INSTALLED=false
ARCH_TESTS_INSTALLED=false
SPIKE_INSTALLED=false
PK_INSTALLED=false
TOOLCHAIN_AVAILABLE=false
ENVIRONMENT_SETUP=false

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
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --arch-test-version)
            ARCH_TEST_VERSION="$2"
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
        --no-spike)
            INSTALL_SPIKE=false
            shift
            ;;
        --no-pk)
            INSTALL_PK=false
            shift
            ;;
        --no-build)
            BUILD_TESTS=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "RISC-V Conformance Tests Installation Script for KryptoNyte"
            echo ""
            echo "Options:"
            echo "  --with-sudo              Use sudo for commands requiring elevated privileges"
            echo "  --quiet                  Reduce output verbosity"
            echo "  --upgrade                Force upgrade/reinstall of existing tools"
            echo "  --install-dir DIR        Installation directory (default: /opt/riscv-conformance)"
            echo "  --arch-test-version V    RISC-V arch test version/branch (default: main)"
            echo "  --spike-version V        Spike simulator version/branch (default: master)"
            echo "  --pk-version V           Proxy kernel version/branch (default: master)"
            echo "  --no-spike               Skip Spike simulator installation"
            echo "  --no-pk                  Skip proxy kernel installation"
            echo "  --no-build               Skip building tests (just clone repositories)"
            echo "  --help, -h               Show this help message"
            echo ""
            echo "This script installs:"
            echo "  - UV Python package manager"
            echo "  - Python 3.10 virtual environment"
            echo "  - RISC-V Architecture Tests"
            echo "  - Spike RISC-V ISA Simulator"
            echo "  - RISC-V Proxy Kernel (pk)"
            echo "  - Test framework and utilities"
            echo ""
            echo "This script checks for (but does not install):"
            echo "  - RISC-V GNU Toolchain (expects existing collab toolchain)"
            echo ""
            echo "Tools are automatically detected and skipped if already installed"
            echo "unless --upgrade flag is used."
            echo ""
            echo "Environment variables set after installation:"
            echo "  RISCV_CONFORMANCE_ROOT   - Path to conformance test root"
            echo "  RISCV_ARCH_TEST_ROOT     - Path to architecture tests"
            echo "  SPIKE_ROOT               - Path to Spike simulator"
            echo "  PK_ROOT                  - Path to proxy kernel"
            echo ""
            echo "Examples:"
            echo "  Install everything with default settings:"
            echo "    $0 --with-sudo"
            echo ""
            echo "  Install to custom directory without Spike:"
            echo "    $0 --with-sudo --install-dir /home/user/riscv-tests --no-spike"
            echo ""
            echo "  Force upgrade all components:"
            echo "    $0 --with-sudo --upgrade"
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

# Function to check if running in Codespace
is_codespace() {
    [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]
}

# Function to check if UV is installed
check_uv() {
    if command_exists uv; then
        local version=$(uv --version 2>/dev/null | head -1)
        print_step "Found UV: $version"
        return 0
    else
        print_step "UV not found"
        return 1
    fi
}

# Function to check if Spike is installed
check_spike() {
    if command_exists spike; then
        local version=$(spike --help 2>&1 | head -1)
        print_step "Found Spike: $version"
        return 0
    elif [ -f "/opt/riscv/bin/spike" ]; then
        print_step "Found Spike at: /opt/riscv/bin/spike"
        return 0
    elif [ -f "$INSTALL_DIR/spike/bin/spike" ]; then
        print_step "Found Spike at: $INSTALL_DIR/spike/bin/spike"
        return 0
    else
        print_step "Spike not found"
        return 1
    fi
}

# Function to check if Proxy Kernel is installed
check_pk() {
    if command_exists pk; then
        print_step "Found Proxy Kernel in system PATH"
        return 0
    elif [ -f "/opt/riscv/bin/pk" ]; then
        print_step "Found Proxy Kernel at: /opt/riscv/bin/pk"
        return 0
    elif [ -f "$INSTALL_DIR/pk/riscv64-unknown-elf/bin/pk" ] || [ -f "$INSTALL_DIR/pk/bin/pk" ]; then
        print_step "Found Proxy Kernel at: $INSTALL_DIR/pk"
        return 0
    else
        print_step "Proxy Kernel not found"
        return 1
    fi
}

# Function to check if RISC-V Architecture Tests are installed
check_arch_tests() {
    if [ -d "$INSTALL_DIR/riscv-arch-test" ] && [ -f "$INSTALL_DIR/riscv-arch-test/README.md" ]; then
        print_step "Found RISC-V Architecture Tests at: $INSTALL_DIR/riscv-arch-test"
        return 0
    else
        print_step "RISC-V Architecture Tests not found"
        return 1
    fi
}

# Function to check if RISC-V toolchain is available
check_riscv_toolchain_available() {
    if command_exists riscv64-unknown-elf-gcc || command_exists riscv32-unknown-elf-gcc; then
        if command_exists riscv64-unknown-elf-gcc; then
            local version=$(riscv64-unknown-elf-gcc --version 2>/dev/null | head -1)
            print_step "Found RISC-V toolchain: $version"
        else
            local version=$(riscv32-unknown-elf-gcc --version 2>/dev/null | head -1)
            print_step "Found RISC-V toolchain: $version"
        fi
        return 0
    else
        print_step "RISC-V toolchain not found"
        return 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_step "Checking system requirements"
    
    # Install all required dependencies upfront if using sudo
    if [ "$USE_SUDO" = true ]; then
        print_step "Installing RISC-V conformance test dependencies"
        
        sudo apt-get update
        
        print_step "Installing essential build tools"
        sudo apt-get install -y \
            build-essential git make gcc g++ autoconf automake autotools-dev cmake ninja-build \
            pkg-config curl wget unzip tar gzip
        
        print_step "Installing RISC-V toolchain build dependencies"
        sudo apt-get install -y \
            libmpc-dev libmpfr-dev libgmp-dev zlib1g-dev libexpat1-dev libglib2.0-dev libncurses-dev
        
        print_step "Installing build utilities"
        sudo apt-get install -y \
            gawk bison flex texinfo gperf libtool patchutils bc m4 device-tree-compiler
        
        print_step "Installing Python development tools"
        sudo apt-get install -y \
            python3 python3-dev python3-venv
        
        print_success "All dependencies installed"
    fi
    
    # Basic verification of critical build tools only
    print_step "Verifying critical build tools"
    
    local critical_missing=()
    
    # Only check the most essential tools needed for the build process
    if ! command_exists git; then
        critical_missing+=("git")
    fi
    
    if ! command_exists make; then
        critical_missing+=("make")
    fi
    
    if ! command_exists gcc; then
        critical_missing+=("gcc")
    fi
    
    if ! command_exists python3; then
        critical_missing+=("python3")
    fi
    
    # If critical tools are missing, try one more installation attempt
    if [ ${#critical_missing[@]} -ne 0 ]; then
        if [ "$USE_SUDO" = true ]; then
            print_warning "Some critical tools missing, attempting installation: ${critical_missing[*]}"
            sudo apt-get update
            sudo apt-get install -y build-essential git python3 autoconf cmake
            
            # Re-check after installation
            if ! command_exists gcc || ! command_exists make; then
                print_error "Critical build tools still missing. Cannot proceed."
                exit 1
            fi
        else
            print_error "Critical build tools missing: ${critical_missing[*]}"
            print_error "Run with --with-sudo to automatically install dependencies"
            exit 1
        fi
    fi
    
    print_success "Critical build tools available"
    print_success "System requirements satisfied"
}

# Function to ensure /opt/riscv/bin exists and is in PATH
setup_riscv_path() {
    print_step "Setting up /opt/riscv/bin directory and PATH"
    
    # Create /opt/riscv/bin if it doesn't exist
    if [ ! -d "/opt/riscv/bin" ]; then
        print_step "Creating /opt/riscv/bin directory"
        run_cmd mkdir -p "/opt/riscv/bin"
        
        # Fix ownership if using sudo
        if [ "$USE_SUDO" = true ]; then
            sudo chown -R $USER:$USER "/opt/riscv"
        fi
    fi
    
    # Check if /opt/riscv/bin is in PATH
    if [[ ":$PATH:" != *":/opt/riscv/bin:"* ]]; then
        print_step "Adding /opt/riscv/bin to PATH for current session"
        export PATH="/opt/riscv/bin:$PATH"
        print_success "/opt/riscv/bin added to PATH"
    else
        print_success "/opt/riscv/bin already in PATH"
    fi
}

# Function to create installation directory
create_install_dir() {
    print_step "Creating installation directory: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ] && [ "$UPGRADE_MODE" = false ]; then
        print_warning "Installation directory already exists"
        read -p "Do you want to continue and potentially overwrite existing files? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled by user"
            exit 1
        fi
    fi
    
    run_cmd mkdir -p "$INSTALL_DIR"
    
    # Fix ownership and permissions if using sudo
    if [ "$USE_SUDO" = true ]; then
        sudo chown -R $USER:$USER "$INSTALL_DIR"
        sudo chmod -R u+w "$INSTALL_DIR"
    fi
    
    # Check if we can write to the directory
    if [ ! -w "$INSTALL_DIR" ]; then
        if [ "$USE_SUDO" = true ]; then
            print_error "Cannot write to installation directory: $INSTALL_DIR"
            print_error "Try running: sudo chown -R \$USER:\$USER $INSTALL_DIR"
        else
            print_error "Cannot write to installation directory: $INSTALL_DIR"
            print_error "Directory may be owned by root. Try running with --with-sudo"
        fi
        exit 1
    fi
    
    print_success "Installation directory ready"
}

# Function to install UV Python package manager
install_uv() {
    print_banner "Installing UV Python Package Manager" "$BLUE"
    
    # Check if UV is already installed
    if [ "$UPGRADE_MODE" = false ] && check_uv >/dev/null 2>&1; then
        print_success "UV already installed - skipping"
        UV_INSTALLED=true
        return 0
    fi
    
    if [ "$UPGRADE_MODE" = true ]; then
        print_step "Upgrade mode: Reinstalling UV"
    fi
    
    print_step "Installing UV Python package manager"
    curl -LsSf https://astral.sh/uv/install.sh | sh || {
        print_error "Failed to install UV"
        return 1
    }
    
    # Add UV to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Verify installation
    if command_exists uv; then
        UV_INSTALLED=true
        print_success "UV Python package manager installed"
        uv --version
        
        print_step "Creating Python 3.10 virtual environment"
        cd "$INSTALL_DIR"
        uv venv --python 3.10 || {
            print_warning "Failed to create Python virtual environment"
            return 1
        }
        
        print_success "Python 3.10 virtual environment created"
        return 0
    else
        print_error "UV installation verification failed"
        return 1
    fi
}

# Function to check existing RISC-V toolchain (no installation)
check_riscv_toolchain() {
    print_banner "Checking RISC-V Toolchain" "$BLUE"
    
    # Check for existing collab toolchain
    if [ -d "/opt/riscv/collab/bin" ] && [ -f "/opt/riscv/collab/bin/riscv32-unknown-elf-gcc" ]; then
        print_step "Found existing collab RISC-V toolchain at /opt/riscv/collab"
        local version=$(/opt/riscv/collab/bin/riscv32-unknown-elf-gcc --version 2>/dev/null | head -1 || echo "Version check failed")
        print_step "Collab toolchain: $version"
        TOOLCHAIN_AVAILABLE=true
        print_success "Using existing collab RISC-V toolchain"
        return 0
    fi
    
    # Check if RISC-V toolchain is available in system PATH
    if check_riscv_toolchain_available >/dev/null 2>&1; then
        print_success "RISC-V toolchain found in system PATH"
        TOOLCHAIN_AVAILABLE=true
        return 0
    fi
    
    print_warning "RISC-V toolchain not found"
    print_warning "Expected collab toolchain at /opt/riscv/collab/bin/riscv32-unknown-elf-gcc"
    print_warning "Please ensure the collab toolchain is installed before running conformance tests"
    
    TOOLCHAIN_AVAILABLE=false
    return 1
}

# Function to install RISC-V Architecture Tests
install_arch_tests() {
    print_banner "Installing RISC-V Architecture Tests" "$PURPLE"
    
    local arch_test_dir="$INSTALL_DIR/riscv-arch-test"
    
    # Check if already installed
    if [ "$UPGRADE_MODE" = false ] && check_arch_tests >/dev/null 2>&1; then
        print_success "RISC-V Architecture Tests already installed - skipping"
        ARCH_TESTS_INSTALLED=true
        return 0
    fi
    
    if [ "$UPGRADE_MODE" = true ]; then
        print_step "Upgrade mode: Reinstalling RISC-V Architecture Tests"
        if [ -d "$arch_test_dir" ]; then
            print_step "Removing existing architecture tests directory"
            run_cmd rm -rf "$arch_test_dir"
        fi
    fi
    
    print_step "Cloning RISC-V Architecture Test repository"
    if [ -d "$arch_test_dir" ]; then
        print_step "Updating existing repository"
        cd "$arch_test_dir"
        git fetch origin
        git checkout "$ARCH_TEST_VERSION"
        git pull origin "$ARCH_TEST_VERSION"
    else
        git clone --depth 1 --branch "$ARCH_TEST_VERSION" \
            https://github.com/riscv-non-isa/riscv-arch-test.git "$arch_test_dir"
    fi
    
    cd "$arch_test_dir"
    
    if [ "$BUILD_TESTS" = true ]; then
        print_step "Setting up Python virtual environment"
        if [ -f "$INSTALL_DIR/.venv/bin/activate" ]; then
            source "$INSTALL_DIR/.venv/bin/activate"
        fi
        
        print_step "Installing Python dependencies for test framework"
        if [ -f "requirements.txt" ]; then
            if command_exists uv && [ "$UV_INSTALLED" = true ]; then
                uv pip install -r requirements.txt
            else
                print_warning "UV not available, falling back to pip3"
                pip3 install --user -r requirements.txt
            fi
        fi
        
        print_step "Setting up test environment"
        # Create a simple configuration for KryptoNyte cores
        cat > kryptonyte_config.yaml << EOF
# KryptoNyte RISC-V Core Configuration for Architecture Tests
kryptonyte_rv32i:
  pluginpath: \$RISCV_ARCH_TEST_ROOT/riscv-target/spike
  ispec: \$RISCV_ARCH_TEST_ROOT/spec/rv32i
  pspec: \$RISCV_ARCH_TEST_ROOT/spec/rv32i
  bsp: \$RISCV_ARCH_TEST_ROOT/riscv-target/spike
  target_run: 1
  jobs: $(nproc)

kryptonyte_rv64i:
  pluginpath: \$RISCV_ARCH_TEST_ROOT/riscv-target/spike
  ispec: \$RISCV_ARCH_TEST_ROOT/spec/rv64i
  pspec: \$RISCV_ARCH_TEST_ROOT/spec/rv64i
  bsp: \$RISCV_ARCH_TEST_ROOT/riscv-target/spike
  target_run: 1
  jobs: $(nproc)
EOF
        
        print_success "Architecture tests configured"
    fi
    
    # Mark as successfully installed
    ARCH_TESTS_INSTALLED=true
    print_success "RISC-V Architecture Tests installed"
}

# Function to install Spike simulator
install_spike() {
    if [ "$INSTALL_SPIKE" = false ]; then
        print_step "Skipping Spike simulator installation"
        return 0
    fi
    
    print_banner "Installing Spike RISC-V ISA Simulator" "$YELLOW"
    
    local spike_dir="$INSTALL_DIR/riscv-isa-sim"
    local spike_install="/opt/riscv"
    
    # Check if Spike is already installed
    if [ "$UPGRADE_MODE" = false ] && check_spike >/dev/null 2>&1; then
        print_success "Spike simulator already installed - skipping"
        SPIKE_INSTALLED=true
        return 0
    fi
    
    if [ "$UPGRADE_MODE" = true ]; then
        print_step "Upgrade mode: Completely removing and rebuilding Spike"
        # Remove source directory completely (may need sudo)
        if [ -d "$spike_dir" ]; then
            print_step "Removing existing Spike source directory"
            run_cmd rm -rf "$spike_dir"
        fi
        # Remove Spike-specific files from /opt/riscv (may need sudo)
        if [ -f "/opt/riscv/bin/spike" ]; then
            print_step "Removing existing Spike installation"
            run_cmd rm -f "/opt/riscv/bin/spike"
            run_cmd rm -f "/opt/riscv/lib/lib"*spike* 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/lib/libriscv.so" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/lib/libfesvr.a" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/lib/libdisasm.a" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/lib/libsoftfloat.so" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/lib/libcustomext.so" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/lib/pkgconfig/riscv-"* 2>/dev/null || true
        fi
    fi
    
    print_step "Cloning Spike repository"
    # Always clone fresh in upgrade mode, otherwise update existing
    if [ "$UPGRADE_MODE" = true ] || [ ! -d "$spike_dir" ]; then
        print_step "Cloning fresh Spike repository"
        git clone --depth 1 --branch "$SPIKE_VERSION" \
            https://github.com/riscv-software-src/riscv-isa-sim.git "$spike_dir"
    else
        print_step "Updating existing Spike repository"
        cd "$spike_dir"
        git fetch origin
        git checkout "$SPIKE_VERSION"
        git pull origin "$SPIKE_VERSION"
    fi
    
    cd "$spike_dir"
    
    print_step "Building Spike simulator"
    # Ensure completely clean build directory
    rm -rf build
    mkdir -p build
    cd build
    ../configure --prefix="$spike_install"
    if make -j$(nproc) && run_cmd make install; then
        SPIKE_INSTALLED=true
        print_success "Spike simulator installed"
    else
        print_error "Spike simulator installation failed"
        return 1
    fi
}

# Function to install proxy kernel
install_pk() {
    if [ "$INSTALL_PK" = false ]; then
        print_step "Skipping proxy kernel installation"
        return 0
    fi
    
    print_banner "Installing RISC-V Proxy Kernel" "$GREEN"
    
    local pk_dir="$INSTALL_DIR/riscv-pk"
    local pk_install="/opt/riscv"
    
    # Check if PK is already installed
    if [ "$UPGRADE_MODE" = false ] && check_pk >/dev/null 2>&1; then
        print_success "Proxy kernel already installed - skipping"
        PK_INSTALLED=true
        return 0
    fi
    
    if [ "$UPGRADE_MODE" = true ]; then
        print_step "Upgrade mode: Completely removing and rebuilding proxy kernel"
        # Remove source directory completely (may need sudo)
        if [ -d "$pk_dir" ]; then
            print_step "Removing existing proxy kernel source directory"
            run_cmd rm -rf "$pk_dir"
        fi
        # Remove pk-specific files from /opt/riscv (may need sudo)
        if [ -f "/opt/riscv/bin/pk" ]; then
            print_step "Removing existing proxy kernel installation"
            run_cmd rm -f "/opt/riscv/bin/pk" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/bin/bbl" 2>/dev/null || true
            run_cmd rm -f "/opt/riscv/bin/dummy_payload" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv64-unknown-elf/include/riscv-pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv64-unknown-elf/lib/riscv-pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv64-unknown-elf/bin/pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv64-unknown-elf/bin/bbl" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv64-unknown-elf/bin/dummy_payload" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv32-unknown-elf/include/riscv-pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv32-unknown-elf/lib/riscv-pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv32-unknown-elf/bin/pk" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv32-unknown-elf/bin/bbl" 2>/dev/null || true
            run_cmd rm -rf "/opt/riscv/riscv32-unknown-elf/bin/dummy_payload" 2>/dev/null || true
        fi
    fi
    
    # Check if RISC-V toolchain is available
    if ! check_riscv_toolchain_available >/dev/null 2>&1; then
        print_error "RISC-V toolchain not available"
        return 1
    fi
    
    print_step "Cloning proxy kernel repository"
    # Always clone fresh in upgrade mode, otherwise update existing
    if [ "$UPGRADE_MODE" = true ] || [ ! -d "$pk_dir" ]; then
        print_step "Cloning fresh proxy kernel repository"
        git clone --depth 1 --branch "$PK_VERSION" \
            https://github.com/riscv-software-src/riscv-pk.git "$pk_dir"
    else
        print_step "Updating existing proxy kernel repository"
        cd "$pk_dir"
        git fetch origin
        git checkout "$PK_VERSION"
        git pull origin "$PK_VERSION"
    fi
    
    cd "$pk_dir"
    
    print_step "Building proxy kernel"
    # Ensure completely clean build directory
    rm -rf build
    mkdir -p build
    cd build
    
    # Set cross-compiler environment variables (prefer collab toolchain)
    if [ -f "/opt/riscv/collab/bin/riscv32-unknown-elf-gcc" ]; then
        export CC=/opt/riscv/collab/bin/riscv32-unknown-elf-gcc
        export CXX=/opt/riscv/collab/bin/riscv32-unknown-elf-g++
        export AR=/opt/riscv/collab/bin/riscv32-unknown-elf-ar
        export RANLIB=/opt/riscv/collab/bin/riscv32-unknown-elf-ranlib
        export STRIP=/opt/riscv/collab/bin/riscv32-unknown-elf-strip
        HOST_TRIPLET=riscv32-unknown-elf
    elif command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
        export CC=riscv32-unknown-elf-gcc
        export CXX=riscv32-unknown-elf-g++
        export AR=riscv32-unknown-elf-ar
        export RANLIB=riscv32-unknown-elf-ranlib
        export STRIP=riscv32-unknown-elf-strip
        HOST_TRIPLET=riscv32-unknown-elf
    elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
        export CC=riscv64-unknown-elf-gcc
        export CXX=riscv64-unknown-elf-g++
        export AR=riscv64-unknown-elf-ar
        export RANLIB=riscv64-unknown-elf-ranlib
        export STRIP=riscv64-unknown-elf-strip
        HOST_TRIPLET=riscv64-unknown-elf
    else
        print_error "No RISC-V toolchain found"
        return 1
    fi
    
    print_step "Using toolchain: $CC"
    
    # Configure for the available toolchain - use rv32im with soft-float to avoid ABI conflicts
    export CFLAGS="-march=rv32im -mabi=ilp32"
    export CXXFLAGS="-march=rv32im -mabi=ilp32"
    ../configure --prefix="$pk_install" --host="$HOST_TRIPLET" --with-arch=rv32im
    if make -j$(nproc) && run_cmd make install; then
        PK_INSTALLED=true
        print_success "Proxy kernel installed"
    else
        print_error "Proxy kernel installation failed"
        return 1
    fi
    
    # Reset environment variables
    unset CC CXX AR RANLIB STRIP CFLAGS CXXFLAGS
}

# Function to set up environment variables
setup_environment() {
    print_banner "Setting up environment variables" "$GREEN"
    
    local env_file="$HOME/.riscv_conformance_env"
    
    print_step "Creating environment configuration file"
    cat > "$env_file" << EOF
# RISC-V Conformance Test Environment Variables
# Source this file or add to your shell profile (.bashrc, .zshrc, etc.)

# Conformance Test Root Directories
export RISCV_CONFORMANCE_ROOT="$INSTALL_DIR"
export RISCV_ARCH_TEST_ROOT="$INSTALL_DIR/riscv-arch-test"

# Simulator and Tools - Install to /opt/riscv to keep with collab toolchain
export SPIKE_ROOT="/opt/riscv"
export PK_ROOT="/opt/riscv"

# RISC-V Toolchain - Use collab toolchain (expected to be pre-installed)
if [ -d "/opt/riscv/collab/bin" ] && [ -f "/opt/riscv/collab/bin/riscv32-unknown-elf-gcc" ]; then
    export RISCV_TOOLCHAIN_ROOT="/opt/riscv/collab"
    export RISCV="/opt/riscv/collab"
    export RISCV_PREFIX="riscv32-unknown-elf-"
    echo "Using collab RISC-V toolchain at /opt/riscv/collab"
elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    export RISCV_TOOLCHAIN_ROOT="\$(dirname \$(dirname \$(which riscv64-unknown-elf-gcc)))"
    export RISCV="\$RISCV_TOOLCHAIN_ROOT"
    export RISCV_PREFIX="riscv64-unknown-elf-"
    echo "Using system RISC-V toolchain"
elif command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
    export RISCV_TOOLCHAIN_ROOT="\$(dirname \$(dirname \$(which riscv32-unknown-elf-gcc)))"
    export RISCV="\$RISCV_TOOLCHAIN_ROOT"
    export RISCV_PREFIX="riscv32-unknown-elf-"
    echo "Using system RISC-V toolchain"
else
    echo "Warning: No RISC-V toolchain found. Please install collab toolchain at /opt/riscv/collab/"
    export RISCV_TOOLCHAIN_ROOT="/opt/riscv/collab"
    export RISCV="/opt/riscv/collab"
    export RISCV_PREFIX="riscv32-unknown-elf-"
fi

# UV Python environment
export UV_PYTHON_ENV="$INSTALL_DIR/.venv"

# Add /opt/riscv/bin to PATH if it exists and isn't already there
if [ -d "/opt/riscv/bin" ] && [[ ":\$PATH:" != *":/opt/riscv/bin:"* ]]; then
    export PATH="/opt/riscv/bin:\$PATH"
fi

# Add tools to PATH (prioritize collab toolchain)
if [ -d "/opt/riscv/collab/bin" ]; then
    export PATH="/opt/riscv/collab/bin:\$SPIKE_ROOT/bin:\$PK_ROOT/bin:\$HOME/.cargo/bin:\$PATH"
else
    export PATH="\$RISCV_TOOLCHAIN_ROOT/bin:\$SPIKE_ROOT/bin:\$PK_ROOT/bin:\$HOME/.cargo/bin:\$PATH"
fi

# Test framework configuration
export RISCV_TARGET="spike"
export RISCV_DEVICE="rv32i_m"
export RISCV_TEST_SUITE="rv32i_m"

# KryptoNyte specific configurations
export KRYPTONYTE_CONFORMANCE_ROOT="\$RISCV_ARCH_TEST_ROOT"
export KRYPTONYTE_TEST_CONFIG="\$RISCV_ARCH_TEST_ROOT/kryptonyte_config.yaml"

# Python path for test framework
export PYTHONPATH="\$RISCV_ARCH_TEST_ROOT:\$PYTHONPATH"

# Activate UV Python environment if available
if [ -f "\$UV_PYTHON_ENV/bin/activate" ]; then
    source "\$UV_PYTHON_ENV/bin/activate"
fi

EOF

    print_step "Environment file created at: $env_file"
    
    # Add to current shell profile if possible
    local shell_profile=""
    if [ -n "$BASH_VERSION" ]; then
        shell_profile="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_profile="$HOME/.zshrc"
    fi
    
    if [ -n "$shell_profile" ] && [ -w "$shell_profile" ]; then
        if ! grep -q "riscv_conformance_env" "$shell_profile"; then
            print_step "Adding environment setup to $shell_profile"
            echo "" >> "$shell_profile"
            echo "# RISC-V Conformance Test Environment" >> "$shell_profile"
            echo "source $env_file" >> "$shell_profile"
            print_success "Environment setup added to shell profile"
        else
            print_warning "Environment setup already exists in shell profile"
        fi
    fi
    
    # Mark environment setup as complete
    ENVIRONMENT_SETUP=true
    print_success "Environment configuration complete"
    
    echo -e "\n${CYAN}To use the RISC-V conformance tests in your current session, run:${NC}"
    echo -e "${WHITE}source $env_file${NC}"
    echo -e "\n${CYAN}Or restart your terminal to load the environment automatically.${NC}"
}

# Function to create test runner scripts
create_test_runners() {
    print_banner "Creating test runner scripts" "$CYAN"
    
    local scripts_dir="$INSTALL_DIR/scripts"
    mkdir -p "$scripts_dir"
    
    # Create a simple test runner for KryptoNyte cores
    cat > "$scripts_dir/run_conformance_tests.sh" << 'EOF'
#!/bin/bash

# KryptoNyte RISC-V Conformance Test Runner
# Usage: ./run_conformance_tests.sh [rv32i|rv64i] [test_suite]

ARCH=${1:-rv32i}
TEST_SUITE=${2:-rv32i_m}

echo "Running RISC-V conformance tests for $ARCH"
echo "Test suite: $TEST_SUITE"

# Activate UV Python environment if available
if [ -f "$RISCV_CONFORMANCE_ROOT/.venv/bin/activate" ]; then
    source "$RISCV_CONFORMANCE_ROOT/.venv/bin/activate"
fi

cd $RISCV_ARCH_TEST_ROOT

# Run the tests
python3 riscv_ctg/main.py \
    --config-yaml kryptonyte_config.yaml \
    --config kryptonyte_$ARCH \
    --suite $TEST_SUITE \
    --work-dir work \
    --verbose

echo "Test results available in: $RISCV_ARCH_TEST_ROOT/work"
EOF

    chmod +x "$scripts_dir/run_conformance_tests.sh"
    
    # Create a test validator script
    cat > "$scripts_dir/validate_core.sh" << 'EOF'
#!/bin/bash

# KryptoNyte Core Validation Script
# Usage: ./validate_core.sh <core_executable> [rv32i|rv64i]

CORE_EXEC="$1"
ARCH="${2:-rv32i}"

if [ -z "$CORE_EXEC" ]; then
    echo "Usage: $0 <core_executable> [rv32i|rv64i]"
    echo "Example: $0 ./zeronyte_core rv32i"
    exit 1
fi

if [ ! -f "$CORE_EXEC" ]; then
    echo "Error: Core executable not found: $CORE_EXEC"
    exit 1
fi

echo "Validating KryptoNyte core: $CORE_EXEC"
echo "Architecture: $ARCH"

# Activate UV Python environment if available
if [ -f "$RISCV_CONFORMANCE_ROOT/.venv/bin/activate" ]; then
    source "$RISCV_CONFORMANCE_ROOT/.venv/bin/activate"
fi

# TODO: Implement core-specific test execution
# This would involve:
# 1. Compiling test programs for the specific core
# 2. Running tests on the core
# 3. Comparing results with reference implementation
# 4. Generating compliance report

echo "Core validation framework ready"
echo "Implement core-specific test execution in this script"
EOF

    chmod +x "$scripts_dir/validate_core.sh"
    
    print_success "Test runner scripts created in $scripts_dir"
}

# Function to verify installation
verify_installation() {
    print_banner "Verifying installation" "$GREEN"
    
    local errors=0
    local warnings=0
    
    print_step "Checking installation status based on component completion"
    
    # Check UV installation status
    if [ "$UV_INSTALLED" = true ]; then
        print_success "UV Python package manager installation completed successfully"
    else
        print_warning "UV Python package manager installation failed or skipped"
        ((warnings++))
    fi
    
    # Check Architecture Tests installation status
    if [ "$ARCH_TESTS_INSTALLED" = true ]; then
        print_success "RISC-V Architecture Tests installation completed successfully"
    else
        print_error "RISC-V Architecture Tests installation failed"
        ((errors++))
    fi
    
    # Check Spike installation status
    if [ "$INSTALL_SPIKE" = true ]; then
        if [ "$SPIKE_INSTALLED" = true ]; then
            print_success "Spike simulator installation completed successfully"
        else
            print_error "Spike simulator installation failed"
            ((errors++))
        fi
    else
        print_success "Spike simulator installation skipped (as requested)"
    fi
    
    # Check PK installation status
    if [ "$INSTALL_PK" = true ]; then
        if [ "$PK_INSTALLED" = true ]; then
            print_success "Proxy kernel installation completed successfully"
        else
            print_warning "Proxy kernel installation failed (may be optional)"
            ((warnings++))
        fi
    else
        print_success "Proxy kernel installation skipped (as requested)"
    fi
    
    # Check toolchain availability (no installation, just verification)
    if [ "$TOOLCHAIN_AVAILABLE" = true ] || check_riscv_toolchain_available >/dev/null 2>&1; then
        TOOLCHAIN_AVAILABLE=true
        print_success "RISC-V toolchain found and available"
    else
        print_warning "RISC-V toolchain not found in PATH"
        print_warning "Expected collab toolchain at /opt/riscv/collab/bin/"
        print_warning "Please ensure the collab toolchain is installed before running conformance tests"
        ((warnings++))
    fi
    
    # Check environment setup status
    if [ "$ENVIRONMENT_SETUP" = true ]; then
        print_success "Environment configuration completed successfully"
    else
        print_warning "Environment configuration was not completed"
        ((warnings++))
    fi
    
    # Summary based on component status
    print_step "Installation verification summary"
    if [ $errors -eq 0 ]; then
        if [ $warnings -eq 0 ]; then
            print_banner "Installation completed successfully!" "$GREEN"
            echo -e "\n${GREEN}✅ All RISC-V conformance test components installed successfully!${NC}"
            echo -e "${GREEN}   The test suite is ready for use with KryptoNyte processors.${NC}"
        else
            print_banner "Installation completed with warnings" "$YELLOW"
            echo -e "\n${YELLOW}⚠️  RISC-V conformance tests installed with $warnings warnings${NC}"
            echo -e "${YELLOW}   Core functionality should work, but some features may be limited${NC}"
        fi
        
        echo -e "\n${CYAN}📋 Component Status Summary:${NC}"
        [ "$UV_INSTALLED" = true ] && echo -e "  🐍 UV Python Manager: ${GREEN}✅ Installed${NC}" || echo -e "  🐍 UV Python Manager: ${YELLOW}⚠️  Not Available${NC}"
        echo -e "  📚 Architecture Tests: ${GREEN}✅ Installed${NC}"
        [ "$INSTALL_SPIKE" = true ] && [ "$SPIKE_INSTALLED" = true ] && echo -e "  🔧 Spike Simulator: ${GREEN}✅ Installed${NC}"
        [ "$INSTALL_PK" = true ] && [ "$PK_INSTALLED" = true ] && echo -e "  ⚙️  Proxy Kernel: ${GREEN}✅ Installed${NC}"
        [ "$TOOLCHAIN_AVAILABLE" = true ] && echo -e "  🛠️  RISC-V Toolchain: ${GREEN}✅ Available${NC}"
        echo -e "  🌍 Environment Setup: ${GREEN}✅ Configured${NC}"
        
        echo -e "\n${CYAN}📁 Installation Locations:${NC}"
        echo -e "  📂 Conformance Root: ${WHITE}$INSTALL_DIR${NC}"
        echo -e "  🐍 UV Python Environment: ${WHITE}$INSTALL_DIR/.venv${NC}"
        echo -e "  📚 Architecture Tests: ${WHITE}$INSTALL_DIR/riscv-arch-test${NC}"
        [ "$INSTALL_SPIKE" = true ] && echo -e "  🔧 Spike Simulator: ${WHITE}$INSTALL_DIR/spike/bin/spike${NC}"
        [ "$INSTALL_PK" = true ] && echo -e "  ⚙️  Proxy Kernel: ${WHITE}$INSTALL_DIR/pk${NC}"
        echo -e "  🌍 Environment File: ${WHITE}$HOME/.riscv_conformance_env${NC}"
        echo -e "  📜 Test Scripts: ${WHITE}$INSTALL_DIR/scripts${NC}"
        
        echo -e "\n${CYAN}🚀 Next Steps:${NC}"
        echo -e "  1. Load environment: ${WHITE}source ~/.riscv_conformance_env${NC}"
        echo -e "  2. Run basic tests: ${WHITE}$INSTALL_DIR/scripts/run_conformance_tests.sh rv32i${NC}"
        echo -e "  3. Validate KryptoNyte cores: ${WHITE}$INSTALL_DIR/scripts/validate_core.sh <core_name>${NC}"
        echo -e "  4. Integrate with KryptoNyte RTL generator"
        
    else
        print_banner "Installation failed" "$RED"
        echo -e "\n${RED}❌ Installation failed with $errors critical component failures${NC}"
        if [ $warnings -gt 0 ]; then
            echo -e "${YELLOW}   Also encountered $warnings warnings${NC}"
        fi
        
        echo -e "\n${CYAN}💥 Failed Components:${NC}"
        [ "$ARCH_TESTS_INSTALLED" != true ] && echo -e "  📚 Architecture Tests: ${RED}❌ Failed${NC}"
        [ "$INSTALL_SPIKE" = true ] && [ "$SPIKE_INSTALLED" != true ] && echo -e "  🔧 Spike Simulator: ${RED}❌ Failed${NC}"
        [ "$INSTALL_PK" = true ] && [ "$PK_INSTALLED" != true ] && echo -e "  ⚙️  Proxy Kernel: ${RED}❌ Failed${NC}"
        
        echo -e "\n${CYAN}🔧 Troubleshooting Suggestions:${NC}"
        echo -e "  1. Review the installation log above for specific error messages"
        echo -e "  2. Check system requirements and dependencies"
        echo -e "  3. Verify disk space and permissions in $INSTALL_DIR"
        echo -e "  4. Try running with --with-sudo if permission issues"
        echo -e "  5. Check network connectivity for repository access"
        
        exit 1
    fi
}

# Main installation flow
main() {
    print_banner "RISC-V Conformance Tests Installation for KryptoNyte" "$BLUE"
    
    # Auto-detect environment
    if is_codespace; then
        print_banner "DETECTED: GitHub Codespace Environment" "$PURPLE"
    else
        print_banner "DETECTED: Standalone Environment" "$PURPLE"
    fi
    
    echo -e "${CYAN}Installation Configuration:${NC}"
    echo -e "  Install Directory: ${WHITE}$INSTALL_DIR${NC}"
    echo -e "  Arch Test Version: ${WHITE}$ARCH_TEST_VERSION${NC}"
    echo -e "  Install Spike: ${WHITE}$INSTALL_SPIKE${NC}"
    echo -e "  Install PK: ${WHITE}$INSTALL_PK${NC}"
    echo -e "  Build Tests: ${WHITE}$BUILD_TESTS${NC}"
    echo -e "  Use Sudo: ${WHITE}$USE_SUDO${NC}"
    echo -e "  Upgrade Mode: ${WHITE}$UPGRADE_MODE${NC}"
    
    # Tool detection summary
    print_banner "Checking Existing Tools" "$CYAN"
    echo -e "${CYAN}Tool Detection Summary:${NC}"
    
    local uv_installed=false
    local arch_tests_found=false
    local spike_found=false
    local pk_found=false
    local toolchain_found=false
    
    if check_uv >/dev/null 2>&1; then
        echo -e "  🐍 UV Python Manager: ${GREEN}Found${NC}"
        uv_installed=true
    else
        echo -e "  🐍 UV Python Manager: ${RED}Not Found${NC}"
    fi
    
    if check_arch_tests >/dev/null 2>&1; then
        echo -e "  📚 Architecture Tests: ${GREEN}Found${NC}"
        arch_tests_found=true
    else
        echo -e "  📚 Architecture Tests: ${RED}Not Found${NC}"
    fi
    
    if check_spike >/dev/null 2>&1; then
        echo -e "  🔧 Spike Simulator: ${GREEN}Found${NC}"
        spike_found=true
    else
        echo -e "  🔧 Spike Simulator: ${RED}Not Found${NC}"
    fi
    
    if check_pk >/dev/null 2>&1; then
        echo -e "  ⚙️  Proxy Kernel: ${GREEN}Found${NC}"
        pk_found=true
    else
        echo -e "  ⚙️  Proxy Kernel: ${RED}Not Found${NC}"
    fi
    
    if check_riscv_toolchain_available >/dev/null 2>&1; then
        echo -e "  🛠️  RISC-V Toolchain: ${GREEN}Found${NC}"
        toolchain_found=true
    else
        echo -e "  🛠️  RISC-V Toolchain: ${RED}Not Found${NC}"
    fi
    
    # Confirm installation
    if [ "$VERBOSE" = true ]; then
        echo ""
        if [ "$UPGRADE_MODE" = true ]; then
            echo "Upgrade mode enabled - will reinstall all tools"
        else
            echo "Normal mode - will skip existing tools"
        fi
        read -p "Continue with installation? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_error "Installation cancelled by user"
            exit 1
        fi
    fi
    
    check_requirements
    setup_riscv_path
    create_install_dir
    install_uv
    check_riscv_toolchain
    install_arch_tests
    install_spike
    install_pk
    create_test_runners
    setup_environment
    verify_installation
    
    print_banner "Installation Complete!" "$GREEN"
    
    # Reset terminal attributes to fix cursor echo issue
    echo -e "\033[0m"  # Reset all attributes
    stty echo          # Ensure terminal is echoing input
}

# Ensure terminal is reset even if script is interrupted
trap 'echo -e "\033[0m"; stty echo' EXIT INT TERM

# Run main function
main "$@"
