import os
import time
import glob
import statistics
import subprocess

def exec_shell_cmd(cmd, stdout_val=subprocess.PIPE):
    try:
        cmd_stdout = subprocess.run([cmd], shell=True, check=True, stdout=stdout_val, stderr=subprocess.STDOUT, universal_newlines=True)

        if stdout_val is not None and cmd_stdout.stdout is not None:
            return cmd_stdout.stdout.strip()

        return cmd_stdout

    except subprocess.CalledProcessError as e:
        print(e.output)

def process_results(test_name, iterations):
    log_test_res_folder = os.path.join(os.getcwd(), "mysql_results", test_name)
    print(log_test_res_folder)
    os.chdir(log_test_res_folder)
    log_files = glob.glob1(log_test_res_folder, "*.log")

    if len(log_files) != iterations:
        raise Exception(f"\nNumber of test result files - {len(log_files)} is not equal to the expected number - {iterations}")

    tpt = 0
    tpt_dict = {}
    tpt_dict['tpt_list'] = []
    for filename in log_files:
        with open(filename, "r") as f:
            for row in f.readlines():
                row = row.split()
                if row:
                    if "queries:" in row[0]:
                        tpt = row[2].split('(')[1]
                        break
    
            tpt_dict['tpt_list'].append(float(tpt))

    tpt_dict['tpt_med'] = '{:0.3f}'.format(statistics.median(tpt_dict['tpt_list']))
    print(f"\nTpt list is: ", tpt_dict['tpt_list'])
    #print(f"\nTpt med is: ", tpt_dict['tpt_med'])
    return tpt_dict['tpt_med']

def run_test(test_name, mode, threads, iterations=1):
    shell_file_path = os.getcwd()+"/mysql/Execute_MySQL_Workload.sh"
    print("\nExecuting MySQL shell script..")
    exec_shell_cmd(f"{shell_file_path} {test_name} {mode} {threads} {iterations}", None)
    print("\nFinished executing the test! Sleeping for 15 seconds before parsing results..")
    time.sleep(15)
    return process_results(test_name, iterations)

