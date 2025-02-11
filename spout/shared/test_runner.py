import json
import os
import re
import subprocess
from configparser import ConfigParser
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


class SharedSpoutletTester:
    """Base class for testing Spout modules"""
    
    def __init__(self, module_name: str, test_cases_path: Optional[str | Path] = None):
        self.module_name = module_name
        self.module_path = self._find_module_path()
        
        # Handle test_cases_path as either a full path or just a filename
        if test_cases_path:
            if isinstance(test_cases_path, str) and not os.path.isabs(test_cases_path):
                # If it's just a filename, append it to the default test directory
                self.test_cases_path = self.module_path / "tests" / test_cases_path
            else:
                self.test_cases_path = Path(test_cases_path)
        else:
            # Default behavior
            self.test_cases_path = self.module_path / "tests" / "test_cases.json"
        
    def _find_module_path(self) -> Path:
        """Find the module directory from the current file"""
        current_path = Path(__file__).parent
        while current_path.name != "spout":
            current_path = current_path.parent
        
        # Check both core and addons directories
        core_path = current_path / "core" / self.module_name
        addon_path = current_path / "addons" / self.module_name
        
        # Return the path that exists, preferring core over addons
        if core_path.exists():
            return core_path
        elif addon_path.exists():
            return addon_path
        else:
            raise Exception(f"Module '{self.module_name}' not found in either core or addons directories")
        
    def _get_default_model(self) -> str:
        """Get the default model from settings.ini"""
        try:
            config = ConfigParser()
            spout_root = Path(__file__).parent
            while spout_root.name != "spout":
                spout_root = spout_root.parent
            
            settings_path = spout_root / "config" / "settings.ini"
            with open(settings_path, 'r', encoding='utf-8-sig') as f:
                config.read_file(f)
            return config.get('General', 'PreferredModel', fallback='Unknown')
        except Exception:
            return "Unknown"
        
    def _clear_sample_files(self) -> None:
        """Clear existing sample files before running tests"""
        samples_dir = self.module_path / "tests" / "samples"
        if samples_dir.exists():
            for file in samples_dir.glob(f"{self.module_name}_*.txt"):
                file.unlink()
        
    def run_module_tests(self, specific_spoutlet: Optional[str] = None, examples: bool = False) -> str:
        """Run tests for the module and return results"""
        if examples:
            self._clear_sample_files()  # Clear existing sample files if examples flag is set
        
        results = []
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        try:
            test_cases = self._load_test_cases()
            default_model = self._get_default_model()
            
            results.extend([
                f"# {self.module_name.capitalize()} Module Test Results",
                f"Test Run: {timestamp}",
                f"Test Model: {default_model}\n"
            ])
            
            for case in test_cases["test_cases"]:
                if not specific_spoutlet or case["spoutlet"] == specific_spoutlet:
                    results.extend(self._run_single_test(case, examples))
                    
        except Exception as e:
            results.append(f"Error running tests: {str(e)}")
            
        return self._save_results(results)
        
    def _load_test_cases(self) -> Dict:
        """Load test cases from JSON file"""
        try:
            if not self.test_cases_path.exists():
                raise FileNotFoundError(f"Test cases file not found: {self.test_cases_path}")
            with open(self.test_cases_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            raise Exception(f"Failed to load test cases from {self.test_cases_path}: {str(e)}")
            
    def _run_single_test(self, case: Dict, examples: bool = False) -> List[str]:
        """Run a single test case and return results"""
        results = []
        
        # Start with test name and spoutlet
        results.extend([
            f"## Test: {case['name']}",
            f"Spoutlet: {case['spoutlet']}"
        ])
        
        # Add all parameters to the input section
        results.append("Input Parameters:")
        for param, value in case.get('parameters', {}).items():
            results.append(f"  {param}: {value}")
        results.append("")  # Empty line after parameters
        
        # Add output section
        results.append("Output:")
        
        # Build CLI command
        cmd = ["spout", self.module_name]
        if case.get("spoutlet") != "default":
            cmd.extend(["-u", case["spoutlet"]])
            
        # Add parameters first
        for param, value in case.get('parameters', {}).items():
            if param != 'input':  # Skip input parameter as it's handled separately
                cmd.extend([f"--{param}", str(value)])
            
        # Add input as positional argument
        input = case.get('parameters', {}).get('input') or case.get('input', '')
        if input:
            cmd.append(input)
            
        # Run command and capture output
        try:
            start_time = datetime.now()
            output = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True,
                timeout=case.get('timeout', 30)
            )
            end_time = datetime.now()
            operation_time = (end_time - start_time).total_seconds()
            
            results.append(output.stdout.rstrip())  # Remove trailing whitespace
            results.append("")  # Add exactly one blank line
            
            SUCCESS_MARK = " [PASS] "
            FAILURE_MARK = " [FAIL] "
            
            # Check if test passed
            test_passed = output.returncode == 0 and re.search(case['expected_pattern'], output.stdout)
            
            if examples and case.get('sample', False) and test_passed:
                self._write_output_to_file(case, cmd, output.stdout)
            
            if test_passed:
                results.append(f"{SUCCESS_MARK} {operation_time:.2f}s")
            else:
                results.append(f"{FAILURE_MARK} {operation_time:.2f}s")
                if output.stderr:
                    results.append(f"Error: {output.stderr}")
                    
        except subprocess.TimeoutExpired:
            results.append(f"{FAILURE_MARK} Test failed - Timeout")
        except Exception as e:
            results.append(f"{FAILURE_MARK} Test failed - Error: {str(e)}")
            
        results.append("\n---\n")
        return results
        
    def _write_output_to_file(self, case: Dict, cmd: List[str], output: str) -> None:
        """Write the command and output to a file"""
        # Create the samples directory if it doesn't exist
        samples_dir = self.module_path / "tests" / "samples"
        samples_dir.mkdir(parents=True, exist_ok=True)
        
        # Create the filename based on module and spoutlet
        filename = f"{self.module_name}_{case['spoutlet']}.txt"
        file_path = samples_dir / filename
        
        # Format command with proper quotes
        formatted_cmd = []
        for i, part in enumerate(cmd):
            if i <= 1:  # 'spout' and module name don't need quotes
                formatted_cmd.append(part)
            elif part.startswith('-'):  # flags don't need quotes
                formatted_cmd.append(part)
            else:  # add quotes around parameters and input
                formatted_cmd.append(f'"{part}"')
        
        # Determine if file exists to handle newlines properly
        file_exists = file_path.exists()
        
        # Append the command and output to the file
        with open(file_path, 'a') as f:
            # Add newline if file already has content
            if file_exists:
                f.write("\n\n")
            f.write("Command:\n")
            f.write(" ".join(formatted_cmd) + "\n\n")
            f.write("Output:\n")
            f.write(output + "\n")
        
    def _save_results(self, results: List[str]) -> str:
        """Save results to file and return results string"""
        results_str = "\n".join(results)
        results_path = self.module_path / "tests" / "test_results.txt"
        
        results_path.parent.mkdir(exist_ok=True)
        with open(results_path, "w") as f:
            f.write(results_str)
            
        return results_str