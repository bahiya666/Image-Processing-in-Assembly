# Image-Processing-in-Assembly
 Overview
This project demonstrates basic image processing operations implemented in assembly language, including reading a PPM (Portable Pixmap) image, computing the CDF (Cumulative Distribution Function) of pixel intensities, performing histogram equalization, and writing the result back to a PPM file.

The project is divided into four main tasks:

Task 1: task1_read_ppm_file - This module reads a PPM image file, parses the header, and stores pixel data in a linked list of PixelNode structs.
Task 2: task2_compute_cdf_values - This module computes the CDF of pixel intensities from the histogram of the image.
Task 3: task3_histogram_equalisation - This module applies histogram equalization to the image using the computed CDF values.
Task 4: task4_write_ppm - This module writes the processed image back to a new PPM file.
Each task performs an essential operation in the image processing pipeline, from reading the image to producing the output.

Project Structure
The project consists of the following modules:

task1_read_ppm_file.asm:

Reads the PPM image file.
Parses the magic number (P6), width, height, and pixel data.
Converts the pixel data into a linked list of PixelNode structs.

task2_compute_cdf_values.asm:
Computes the histogram of pixel intensities from the image.
Calculates the CDF from the histogram.

task3_histogram_equalisation.asm:
Applies histogram equalization to the image using the CDF values.
Adjusts the pixel intensities to achieve an equalized histogram.

task4_write_ppm.asm:
Writes the processed image back to a PPM file.
Writes the magic number, width, height, and pixel data.

How to Build and Run
Requirements
Assembler: The code is written in x86-64 Assembly and requires an assembler such as NASM.
Linux Environment: The code makes use of Linux system calls for file operations and memory handling, so a Linux environment is required.
File Format: The code works with the PPM P6 format, which is a binary format where pixel data is stored as RGB triplets.

Steps to Compile and Run
Assemble the code:
Each task is a separate assembly file, so you will need to assemble them into object files first.

nasm -f elf64 -o task1_read_ppm_file.o task1_read_ppm_file.asm
nasm -f elf64 -o task2_compute_cdf_values.o task2_compute_cdf_values.asm
nasm -f elf64 -o task3_histogram_equalisation.o task3_histogram_equalisation.asm
nasm -f elf64 -o task4_write_ppm.o task4_write_ppm.asm

Link the object files:
Link the object files into an executable. You can use ld for this.

ld -o image_processor task1_read_ppm_file.o task2_compute_cdf_values.o task3_histogram_equalisation.o task4_write_ppm.o

Run the program:
To run the program, pass the input PPM file and specify the output PPM file.
./image_processor input.ppm output.ppm

This will:
Read the input.ppm file.
Compute the CDF and apply histogram equalization.
Write the processed image to output.ppm.

Task Details
Task 1: task1_read_ppm_file
This task is responsible for reading a PPM image file and converting it into a linked list of PixelNode structs. The code parses the header information (magic number, width, height) and extracts pixel data in RGB format. The pixel data is stored in a linked list to allow efficient traversal and modification.

Key Functions:
readPPMFile: Opens the PPM file, reads the header, and populates the linked list with pixel data.
Task 2: task2_compute_cdf_values
This task computes the histogram and cumulative distribution function (CDF) for the pixel intensities. The histogram counts the occurrences of each intensity level (0-255) for the red, green, and blue channels. The CDF is then computed by accumulating the histogram values.

Key Functions:
computeCDFValues: Traverses the linked list and updates the histogram based on the pixel intensities. Then, it computes the CDF based on the histogram.
Task 3: task3_histogram_equalisation
This task performs histogram equalization using the computed CDF values. The CDF is used to adjust the pixel intensities to stretch the dynamic range of the image, which can enhance the image contrast.

Key Functions:
applyHistogramEqualisation: Traverses the linked list of pixels, updates the RGB values using the CDF, and applies the histogram equalization transformation.
Task 4: task4_write_ppm
This task writes the processed image to a new PPM file. It writes the image header (magic number, width, height, and maximum color value) and then writes the pixel data in binary format.

Key Functions:
writePPM: Opens the output file, writes the header information, and writes the pixel data from the linked list into the PPM file.
