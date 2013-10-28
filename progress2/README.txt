without_opengl.top.txt
- Shows that android applications (com.*) are not running without OpenGL 
  libraries.

without_opengl.helloworld.txt
- Proves that OpenCL is still functional without OpenGL libraries 
  available.

sample_gpu_timeout.25_times.txt
- Sample the time it takes in seconds for an OpenCL program containing an 
  infinite loop to execute until the device is forcefully rebooted 
  (performed 25 times).

sample_cpu_gpu_communication.100_datapoints.txt
- Measure the time it takes to copy an input array over varying sizes 
  (helloworld with varying input/output size parameter)
- Measure the time it takes to read an output array over varying sizes 
  (helloworld with varying input/output size parameter)

sample_empty_kernel.25_times.txt
- To protect against overestimates of kernel runtime, measure the time to 
  invoke an OpenCL program that does nothing (empty_kernel)

sample_opencl_aes_sizes.txt
- Measure the time it takes to run the OpenCL AES kernel on different sizes of input
