import os
import logging
from typing import Dict

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()


class zeronyte(pluginTemplate):
    __model__ = "zeronyte-rv32i"
    __version__ = "0.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        config: Dict = kwargs.get("config")
        if config is None:
            raise SystemExit("zeronyte plugin requires configuration")

        sim_name = config.get("sim", "zeronyte_sim")
        sim_dir = config.get("PATH", "")
        self.dut_exe = os.path.join(sim_dir, sim_name)
        if not os.path.isabs(self.dut_exe):
            self.dut_exe = os.path.abspath(self.dut_exe)

        self.num_jobs = str(config.get("jobs", 1))
        self.pluginpath = os.path.abspath(config["pluginpath"])
        self.isa_spec = os.path.abspath(config["ispec"])
        self.platform_spec = os.path.abspath(config["pspec"])
        self.target_run = config.get("target_run", "1") != "0"

    def initialise(self, suite, work_dir, archtest_env):
        self.work_dir = work_dir
        self.suite_dir = suite
        self.archtest_env = archtest_env

        self.linker = os.path.join(self.pluginpath, "env", "link.ld")
        self.local_env = os.path.join(self.pluginpath, "env")
        self.arch_env = archtest_env

        self.compile_cmd_template = (
            "riscv64-unknown-elf-gcc -march={march} -mabi=ilp32 "
            "-mcmodel=medany -static -nostdlib -nostartfiles -g "
            "-T {linker} -I {local_env} -I {arch_env} {test} -o {elf} {macros}"
        )

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)["hart0"]
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"

    def runTests(self, testList):
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = "make -k -j" + self.num_jobs
        timeout_env = os.environ.get("RISCOF_TIMEOUT") or os.environ.get("TIMEOUT")
        try:
            timeout = int(timeout_env) if timeout_env else 300
        except ValueError:
            timeout = 300

        for testname, testentry in testList.items():
            test_dir = testentry["work_dir"]
            elf_path = os.path.join(test_dir, "test.elf")
            sig_path = os.path.join(test_dir, self.name[:-1] + ".signature")
            log_path = os.path.join(test_dir, self.name[:-1] + ".log")

            compile_macros = "-DXLEN=" + self.xlen
            if testentry["macros"]:
                compile_macros += " -D" + " -D".join(testentry["macros"])

            compile_cmd = self.compile_cmd_template.format(
                march=testentry["isa"].lower(),
                linker=self.linker,
                local_env=self.local_env,
                arch_env=self.arch_env,
                test=testentry["test_path"],
                elf=elf_path,
                macros=compile_macros,
            )

            if self.target_run:
                run_cmd = (
                    f"{self.dut_exe} --elf {elf_path} --signature {sig_path} "
                    f"--log {log_path} --max-cycles 1000000"
                )
            else:
                run_cmd = "echo 'target run disabled'"

            execute = f"@cd {test_dir}; {compile_cmd}; {run_cmd};"
            make.add_target(execute)

        make.execute_all(self.work_dir, timeout=timeout)

        if not self.target_run:
            raise SystemExit(0)
