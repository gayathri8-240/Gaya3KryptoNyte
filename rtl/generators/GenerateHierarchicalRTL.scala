// KryptoNyte Hierarchical RTL Generator
// Generates timed, hierarchical Verilog RTL with flexible path configuration
// Place in: KryptoNyte/cores/generators/
// Run from: KryptoNyte/cores/ with sbt 'runMain generators.GenerateHierarchicalRTL'

package generators

import circt.stage.ChiselStage 
import sys.process._  
import java.io.File   
import java.nio.file.{Files, Paths, StandardCopyOption, NoSuchFileException} 
import java.io.IOException
import java.io.PrintStream
import java.io.OutputStream
import scala.util.{Try, Success, Failure}

// Import KryptoNyte modules
import ALUs.ALU32
import BranchUnit.BranchUnit
import Decoders.RV32IDecodeModule
import LoadUnit.LoadUnit
import RegFiles.RegFileMT2R1WVec
import StoreUnit.StoreUnit
import TetraNyte.TetraNyteRV32ICore
import ZeroNyte.ZeroNyteRV32ICore
import OctoNyte.OctoNyteRV32ICore

// Note: RV32IDecode is an object (not a Module class), so it's not imported for RTL generation

// Configuration case class for flexible path management
case class RTLGeneratorConfig(
  // Core family and variant
  coreFamily: String = "ZeroNyte",
  coreVariant: String = "rv32i",
  
  // Output directories (can be absolute or relative paths)
  outputRoot: String = "generated",
  firrtlDir: String = "firrtl",
  systemVerilogDir: String = "systemverilog_hierarchical",
  verilogDir: String = "verilog_hierarchical",
  timedRTLDir: String = "verilog_hierarchical_timed",
  annotationsDir: String = "annotations",
  
  // External tool paths (auto-detected if empty)
  firtoolPath: String = "",
  sv2vPath: String = "",
  yosysPath: String = "",
  
  // PDK configuration
  pdkRoot: String = "",
  standardCellLibrary: String = "",
  
  // Generation options
  preserveAggregates: Boolean = true,
  preserveValues: Boolean = true,
  disableRandomization: Boolean = true,
  optimizeForASIC: Boolean = true,  // Default to ASIC synthesis optimization
  generateAnnotations: Boolean = true,
  
  // Cleanup options
  deleteIntermediateFiles: Boolean = false,
  verbose: Boolean = true
) {
  
  // Computed paths
  def fullOutputRoot: String = if (Paths.get(outputRoot).isAbsolute) outputRoot else s"${System.getProperty("user.dir")}/$outputRoot"
  def fullFirrtlPath: String = s"$fullOutputRoot/$firrtlDir"
  def fullSystemVerilogPath: String = s"$fullOutputRoot/$systemVerilogDir"
  def fullVerilogPath: String = s"$fullOutputRoot/$verilogDir"
  def fullTimedRTLPath: String = s"$fullOutputRoot/$timedRTLDir"
  def fullAnnotationsPath: String = s"$fullOutputRoot/$annotationsDir"
  
  // PDK auto-discovery
  def discoverPDK(): RTLGeneratorConfig = {
    if (pdkRoot.nonEmpty) return this
    
    val pdkSearchPaths = Seq(
      "/opt/skywater-pdk/pdks/sky130A",
      "/usr/local/share/pdk/sky130A",
      System.getenv("PDK_ROOT"),
      System.getenv("SKYWATER_PDK_ROOT")
    ).filter(_ != null)
    
    val discoveredPDK = pdkSearchPaths.find(path => Files.exists(Paths.get(path)))
    
    discoveredPDK match {
      case Some(pdk) =>
        val libPath = s"$pdk/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
        if (Files.exists(Paths.get(libPath))) {
          this.copy(pdkRoot = pdk, standardCellLibrary = libPath)
        } else {
          this
        }
      case None => this
    }
  }
  
  // Create all necessary directories
  def createDirectories(): Unit = {
    val dirs = Seq(fullFirrtlPath, fullSystemVerilogPath, fullVerilogPath, fullTimedRTLPath, fullAnnotationsPath)
    dirs.foreach { dir =>
      val path = Paths.get(dir)
      if (!Files.exists(path)) {
        Files.createDirectories(path)
        if (verbose) println(s"Created directory: $dir")
      }
    }
  }
}

// Module specification for generation
case class ModuleSpec(
  generator: () => chisel3.Module,
  name: String,
  description: String = "",
  family: String = "ZeroNyte",
  variant: String = "rv32i"
)

object GenerateHierarchicalRTL extends App {
  
  // Parse command line arguments
  val config = parseArgs(args)
  
  // Auto-discover PDK if not specified
  val finalConfig = config.discoverPDK()
  
  // Create output directories
  finalConfig.createDirectories()
  
  // Print configuration
  if (finalConfig.verbose) {
    printConfiguration(finalConfig)
  }
  
  // Modules to generate - easily configurable
  val modulesToGenerate = getModulesToGenerate(finalConfig)
  
  // Generate RTL for each module
  modulesToGenerate.foreach { moduleSpec =>
    try {
      generateModuleRTL(moduleSpec, finalConfig)
    } catch {
      case e: Exception =>
        println(s"Error generating RTL for ${moduleSpec.name}: ${e.getMessage}")
        if (finalConfig.verbose) e.printStackTrace()
        throw e
    }
  }
  
  println("\n" + "="*80)
  println("Hierarchical RTL generation completed successfully!")
  println("="*80)
  
  // Helper functions
  
  def parseArgs(args: Array[String]): RTLGeneratorConfig = {
    var config = RTLGeneratorConfig()
    
    var i = 0
    while (i < args.length) {
      args(i) match {
        case "--core-family" => 
          config = config.copy(coreFamily = args(i + 1))
          i += 2
        case "--core-variant" => 
          config = config.copy(coreVariant = args(i + 1))
          i += 2
        case "--output-root" => 
          config = config.copy(outputRoot = args(i + 1))
          i += 2
        case "--pdk-root" => 
          config = config.copy(pdkRoot = args(i + 1))
          i += 2
        case "--standard-cell-lib" => 
          config = config.copy(standardCellLibrary = args(i + 1))
          i += 2
        case "--optimize-asic" => 
          config = config.copy(optimizeForASIC = true)
          i += 1
        case "--no-optimize" => 
          config = config.copy(optimizeForASIC = false)
          i += 1
        case "--cleanup" => 
          config = config.copy(deleteIntermediateFiles = true)
          i += 1
        case "--quiet" => 
          config = config.copy(verbose = false)
          i += 1
        case "--help" | "-h" =>
          printHelp()
          System.exit(0)
        case _ => 
          println(s"Unknown argument: ${args(i)}")
          i += 1
      }
    }
    
    config
  }
  
  def printHelp(): Unit = {
    println("""
KryptoNyte Hierarchical RTL Generator

Usage: sbt 'runMain kryptonyte.generators.GenerateHierarchicalRTL [options]'

Options:
  --core-family <name>        Core family (ZeroNyte, PipeNyte, TetraNyte, OctoNyte)
  --core-variant <variant>    Core variant (rv32i, rv64i, etc.)
  --output-root <path>        Root directory for generated files
  --pdk-root <path>           PDK root directory (auto-discovered if not specified)
  --standard-cell-lib <path>  Standard cell library file
  --optimize-asic             Enable ASIC optimization during synthesis
  --no-optimize              Disable ASIC optimization (default)
  --cleanup                   Delete intermediate files after generation
  --quiet                     Reduce output verbosity
  --help, -h                  Show this help message

Examples:
  # Generate ZeroNyte RV32I with default settings
  sbt 'runMain kryptonyte.generators.GenerateHierarchicalRTL'
  
  # Generate OctoNyte with custom output directory
  sbt 'runMain kryptonyte.generators.GenerateHierarchicalRTL --core-family OctoNyte --output-root /tmp/rtl'
  
  # Generate with ASIC optimization
  sbt 'runMain kryptonyte.generators.GenerateHierarchicalRTL --optimize-asic --pdk-root /opt/skywater-pdk/pdks/sky130A'

Environment Variables:
  PDK_ROOT                    PDK root directory
  SKYWATER_PDK_ROOT          SkyWater PDK root directory
  FIRTOOL_PATH               Path to firtool binary
  SV2V_PATH                  Path to sv2v binary
  YOSYS_PATH                 Path to yosys binary
""")
  }
  
  def printConfiguration(config: RTLGeneratorConfig): Unit = {
    println("\n" + "="*80)
    println("KryptoNyte Hierarchical RTL Generator Configuration")
    println("="*80)
    println(s"Core Family:           ${config.coreFamily}")
    println(s"Core Variant:          ${config.coreVariant}")
    println(s"Output Root:           ${config.fullOutputRoot}")
    println(s"FIRRTL Directory:      ${config.fullFirrtlPath}")
    println(s"SystemVerilog Dir:     ${config.fullSystemVerilogPath}")
    println(s"Verilog Directory:     ${config.fullVerilogPath}")
    println(s"Timed RTL Directory:   ${config.fullTimedRTLPath}")
    println(s"PDK Root:              ${if (config.pdkRoot.nonEmpty) config.pdkRoot else "Not configured"}")
    println(s"Standard Cell Library: ${if (config.standardCellLibrary.nonEmpty) config.standardCellLibrary else "Not configured"}")
    println(s"ASIC Optimization:     ${config.optimizeForASIC}")
    println(s"Preserve Aggregates:   ${config.preserveAggregates}")
    println(s"Generate Annotations:  ${config.generateAnnotations}")
    println("="*80 + "\n")
  }
  
  def getModulesToGenerate(config: RTLGeneratorConfig): Seq[ModuleSpec] = {
    // This would be expanded based on the core family and variant
    config.coreFamily match {
      case "Library" => getLibraryModules(config.coreVariant)
      case "ZeroNyte" => getZeroNyteModules(config.coreVariant)
      case "PipeNyte" => getPipeNyteModules(config.coreVariant)
      case "TetraNyte" => getTetraNyteModules(config.coreVariant)
      case "OctoNyte" => getOctoNyteModules(config.coreVariant)
      case _ => 
        println(s"Warning: Unknown core family ${config.coreFamily}, using ZeroNyte")
        getZeroNyteModules(config.coreVariant)
    }
  }

  private def getRV32ILibraryModules(family: String): Seq[ModuleSpec] = Seq(
    ModuleSpec(() => new ALU32, "ALU32", "32-bit ALU", family, "rv32i"),
    ModuleSpec(() => new BranchUnit, "BranchUnit", "Branch decision unit", family, "rv32i"),
    ModuleSpec(() => new LoadUnit, "LoadUnit", "Load unit for RV32I", family, "rv32i"),
    ModuleSpec(() => new StoreUnit, "StoreUnit", "Store unit with mask generation", family, "rv32i"),
    ModuleSpec(() => new RegFileMT2R1WVec(), "RegFileMT2R1WVec", "Multithreaded 2R1W register file", family, "rv32i"),
    ModuleSpec(() => new RV32IDecodeModule, "RV32IDecodeModule", "RV32I instruction decoder", family, "rv32i")
  )
  
  def getLibraryModules(variant: String): Seq[ModuleSpec] = {
    variant match {
      case "rv32i" => getRV32ILibraryModules("Library")
      case _ => Seq.empty
    }
  }
  
  def getZeroNyteModules(variant: String): Seq[ModuleSpec] = {
    variant match {
      case "rv32i" =>
        getRV32ILibraryModules("ZeroNyte") :+
          ModuleSpec(() => new ZeroNyteRV32ICore, "ZeroNyteRV32ICore", "Single-cycle RV32I core", "ZeroNyte", "rv32i")
      case _ => Seq.empty
    }
  }
  
  def getPipeNyteModules(variant: String): Seq[ModuleSpec] = {
    // Placeholder for PipeNyte modules
    Seq.empty
  }
  
  def getTetraNyteModules(variant: String): Seq[ModuleSpec] = {
    variant match {
      case "rv32i" =>
        // Generate all building blocks plus the threaded core itself
        val libraryBlocks = getRV32ILibraryModules("TetraNyte")
        libraryBlocks :+
          ModuleSpec(() => new TetraNyteRV32ICore, "TetraNyteRV32ICore", "Four-thread barrel-threaded RV32I core", "TetraNyte", "rv32i")
      case _ => Seq.empty
    }
  }
  
  def getOctoNyteModules(variant: String): Seq[ModuleSpec] = {
    variant match {
      case "rv32i" =>
        val libraryBlocks = getRV32ILibraryModules("OctoNyte")
        libraryBlocks :+
          ModuleSpec(() => new OctoNyteRV32ICore, "OctoNyteRV32ICore", "Eight-thread, 4-wide packet barrel-threaded RV32I core", "OctoNyte", "rv32i")
      case _ => Seq.empty
    }
  }
  
  def generateModuleRTL(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    println(s"\n${"="*60}")
    println(s"Generating RTL for ${moduleSpec.name}")
    println(s"Family: ${moduleSpec.family}, Variant: ${moduleSpec.variant}")
    println(s"Description: ${moduleSpec.description}")
    println(s"${"="*60}")
    
    // Step 1: Generate FIRRTL
    generateFIRRTL(moduleSpec, config)
    
    // Step 2: Generate hierarchical SystemVerilog
    generateHierarchicalSystemVerilog(moduleSpec, config)
    
    // Step 3: Convert SystemVerilog to Verilog
    convertSystemVerilogToVerilog(moduleSpec, config)
    
    // Step 4: Generate timed hierarchical RTL
    generateTimedHierarchicalRTL(moduleSpec, config)
    
    // Step 5: Cleanup if requested
    if (config.deleteIntermediateFiles) {
      cleanupIntermediateFiles(moduleSpec, config)
    }
    
    println(s"✅ Successfully generated RTL for ${moduleSpec.name}")
  }
  
  def generateFIRRTL(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    if (config.verbose) println(s"${moduleSpec.name}: Generating FIRRTL...")
    
    val firrtlArgs = Array(
      "--target", "firrtl",
      "--dump-fir",
      "--preserve-aggregate", if (config.preserveAggregates) "all" else "none",
      "--target-dir", config.fullFirrtlPath
    )
    
    val firtoolPath = discoverTool("firtool", config.firtoolPath)
    val finalArgs = if (firtoolPath.nonEmpty) {
      firrtlArgs ++ Array("--firtool-binary-path", firtoolPath)
    } else {
      firrtlArgs
    }
    
    (new ChiselStage).execute(
      finalArgs,
      Seq(chisel3.stage.ChiselGeneratorAnnotation(moduleSpec.generator))
    )
    
    if (config.verbose) println(s"✅ FIRRTL generated for ${moduleSpec.name}")
  }
  
  def generateHierarchicalSystemVerilog(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    if (config.verbose) println(s"${moduleSpec.name}: Generating hierarchical SystemVerilog...")
    
    val firtoolPath = discoverTool("firtool", config.firtoolPath)
    if (firtoolPath.isEmpty) {
      println("Warning: firtool not found, skipping SystemVerilog generation")
      return
    }
    
    // Prefer the moduleSpec-provided name, but fall back to the most recently generated FIR
    val preferredFir = new File(s"${config.fullFirrtlPath}/${moduleSpec.name}.fir")
    val firFile = if (preferredFir.exists()) {
      preferredFir
    } else {
      val firs = Option(new File(config.fullFirrtlPath).listFiles())
        .getOrElse(Array.empty)
        .filter(f => f.getName.endsWith(".fir"))
        .sortBy(_.lastModified())
        .reverse
      firs.headOption.getOrElse(preferredFir)
    }
    if (!firFile.exists()) {
      throw new RuntimeException(s"FIRRTL file not found for ${moduleSpec.name} in ${config.fullFirrtlPath}")
    }

    val svFile = new File(s"${config.fullSystemVerilogPath}/${moduleSpec.name}.sv")
    val annotationFile = new File(s"${config.fullAnnotationsPath}/${moduleSpec.name}_annotations.txt")
    
    val firtoolCommand = Seq(
      firtoolPath,
      "--verilog",
      "-o", svFile.getAbsolutePath,
      "--preserve-aggregate", if (config.preserveAggregates) "all" else "none",
      "--preserve-values", if (config.preserveValues) "all" else "none"
    ) ++ (if (config.disableRandomization) Seq("--disable-all-randomization") else Seq.empty) ++
      (if (config.generateAnnotations) Seq(s"--output-annotation-file=${annotationFile.getAbsolutePath}") else Seq.empty) ++
      Seq("--format=fir", firFile.getAbsolutePath)
    
    val result = firtoolCommand.!
    if (result != 0) {
      throw new RuntimeException(s"firtool execution failed with code $result")
    }
    
    if (config.verbose) println(s"✅ Hierarchical SystemVerilog generated for ${moduleSpec.name}")
  }
  
  def convertSystemVerilogToVerilog(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    if (config.verbose) println(s"${moduleSpec.name}: Converting SystemVerilog to Verilog...")
    
    val sv2vPath = discoverTool("sv2v", config.sv2vPath)
    if (sv2vPath.isEmpty) {
      println("Warning: sv2v not found, skipping Verilog conversion")
      return
    }
    
    val svFile = new File(s"${config.fullSystemVerilogPath}/${moduleSpec.name}.sv")
    val vFile = new File(s"${config.fullVerilogPath}/${moduleSpec.name}.v")
    
    val sv2vCommand = Seq(sv2vPath, svFile.getAbsolutePath)
    val result = (sv2vCommand #> vFile).!
    
    if (result != 0) {
      throw new RuntimeException(s"sv2v execution failed with code $result")
    }
    
    if (config.verbose) println(s"✅ Verilog conversion completed for ${moduleSpec.name}")
  }
  
  def generateTimedHierarchicalRTL(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    if (config.verbose) println(s"${moduleSpec.name}: Generating timed hierarchical RTL...")
    
    val yosysPath = discoverTool("yosys", config.yosysPath)
    if (yosysPath.isEmpty) {
      println("Warning: yosys not found, skipping timed RTL generation")
      return
    }
    
    val verilogInFile = new File(s"${config.fullVerilogPath}/${moduleSpec.name}.v")
    val verilogOutFile = new File(s"${config.fullTimedRTLPath}/${moduleSpec.name}.v")
    
    val yosysScript = if (config.optimizeForASIC && config.standardCellLibrary.nonEmpty) {
      s"""
      read_liberty -lib ${config.standardCellLibrary};
      read_verilog -sv ${verilogInFile.getAbsolutePath};
      proc;
      hierarchy -check;
      prep -top ${moduleSpec.name};
      techmap;
      dfflibmap -liberty ${config.standardCellLibrary};
      abc -liberty ${config.standardCellLibrary};
      opt_clean;
      stat;
      write_verilog -noattr ${verilogOutFile.getAbsolutePath}
      """
    } else {
      s"""
      read_verilog -sv ${verilogInFile.getAbsolutePath};
      synth -top ${moduleSpec.name};
      write_verilog ${verilogOutFile.getAbsolutePath}
      """
    }
    
    val yosysCommand = Seq(yosysPath, "-p", yosysScript.trim)
    
    if (config.verbose) {
      println(s"Yosys command: ${yosysCommand.mkString(" ")}")
    }
    
    val result = yosysCommand.!
    if (result != 0) {
      throw new RuntimeException(s"yosys execution failed with code $result")
    }
    
    if (config.verbose) println(s"✅ Timed hierarchical RTL generated for ${moduleSpec.name}")
  }
  
  def cleanupIntermediateFiles(moduleSpec: ModuleSpec, config: RTLGeneratorConfig): Unit = {
    if (config.verbose) println(s"${moduleSpec.name}: Cleaning up intermediate files...")
    
    val filesToDelete = Seq(
      s"${config.fullFirrtlPath}/${moduleSpec.name}.fir",
      s"${config.fullSystemVerilogPath}/${moduleSpec.name}.sv"
    )
    
    filesToDelete.foreach { filePath =>
      Try {
        Files.deleteIfExists(Paths.get(filePath))
      } match {
        case Success(_) => if (config.verbose) println(s"Deleted: $filePath")
        case Failure(e) => if (config.verbose) println(s"Failed to delete $filePath: ${e.getMessage}")
      }
    }
  }
  
  def discoverTool(toolName: String, configPath: String): String = {
    // Check config path first
    if (configPath.nonEmpty && Files.exists(Paths.get(configPath))) {
      return configPath
    }
    
    // Check environment variable
    val envVar = s"${toolName.toUpperCase}_PATH"
    val envPath = System.getenv(envVar)
    if (envPath != null && Files.exists(Paths.get(envPath))) {
      return envPath
    }
    
    // Check if tool is in PATH
    Try {
      val result = s"which $toolName".!!.trim
      if (result.nonEmpty && Files.exists(Paths.get(result))) {
        return result
      }
    }
    
    // Tool not found
    ""
  }
}
