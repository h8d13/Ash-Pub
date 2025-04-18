import subprocess
import sys
###################################
######## SPECS CONFIG #########
arch="x86_64"
ram = 8096
cores = 8
port = ":0" # Use any vnc viewer :)
image_name = "./c/myvm3.qcow2"             # > Alpine
iso_name = "./d/alpine.iso"           
###################################

boot_vncvm(image_name, iso_name)
#run_vncvm(image_name)

def boot_vncvm(image_name, iso_name):
    # Run the VM
    print(f"Started {image_name}, with {cores} cores and {ram} MB of RAM.")
    simulate_spin_animation(duration=10)
    command = f"qemu-system-{arch} -enable-kvm -m {ram} -cpu host -smp {cores} -hda {image_name} -boot d -cdrom {iso_name} -serial mon:stdio -display none"
    try:
        # Start the QEMU process
        process = subprocess.Popen(command, shell=True)

        # Poll the process for any interruptions or completion
        while True:
            # Check if the QEMU process is still running
            retcode = process.poll()
            if retcode is not None:  # If process has finished or terminated
                process.terminate()
                process.wait() # Wait for proper close
                break

            # Sleep for a bit to allow for periodic checks
            time.sleep(0.5)

    except Exception as e:
        print(f"Error while running QEMU: {e}")
    finally:
        print("Reboot to hardisk, recommend: cp your qcow2 file.")


def run_vncvm(image_name):
    # Run the VM
    print(f"Started {image_name}, with {cores} cores and {ram} MB of RAM.")
    simulate_spin_animation(duration=10)
    command = f"qemu-system-{arch} -enable-kvm -m {ram} -cpu host -smp {cores} -hda {image_name} -boot c -serial mon:stdio -display none -vnc {port}"
    try:
        # Start the QEMU process
        process = subprocess.Popen(command, shell=True)

        # Poll the process for any interruptions or completion
        while True:
            # Check if the QEMU process is still running
            retcode = process.poll()
            if retcode is not None:  # If process has finished or terminated
                process.terminate()
                process.wait() # Wait for proper close
                break

            # Sleep for a bit to allow for periodic checks
            time.sleep(0.5)

    except Exception as e:
        print(f"Error while running QEMU: {e}")
    finally:
        print("Goodbye.")
