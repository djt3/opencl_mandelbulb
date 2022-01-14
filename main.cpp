#include <cstdint>
#include <fstream>
#include <iostream>
#include <CL/opencl.hpp>
#include <SFML/Graphics.hpp>

#define CHECK(a, msg) if (a != CL_SUCCESS) { std::cerr << msg << std::endl; return false; }

namespace context {
    cl::Device device;
    cl::Context context;
    cl::Program program;
}

bool init_opencl() {
    cl::vector<cl::Platform> platforms;
    CHECK(cl::Platform::get(&platforms), "Error getting platforms!");

    std::vector<cl::Device> all_devices;
    CHECK(platforms[0].getDevices(CL_DEVICE_TYPE_GPU, &all_devices), "Error getting devices!");

    // store the default GPU device
    context::device = all_devices[0];

    cl_context_properties context_properties[3] = {CL_CONTEXT_PLATFORM, (cl_context_properties) (platforms[0])(), 0};

    cl_int err;
    context::context = cl::Context(CL_DEVICE_TYPE_GPU, context_properties, NULL, NULL, &err);

    CHECK(err, "Error initializing context!");

    // read kernels from kernels.cl file
    std::ifstream file("kernels.cl");
    std::string kernels(std::istreambuf_iterator<char>(file), (std::istreambuf_iterator<char>()));

    // create a source list containing the kernels file
    cl::Program::Sources sources({kernels});

    // create a program
    context::program = cl::Program(context::context, sources);

    // attempt to buld program
    if (context::program.build({context::device}) != CL_SUCCESS) {
        std::cout << "Error building: " << context::program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(context::device) << std::endl;
        return false;
    }

    return true;
}

int main()
{
    if (!init_opencl()) {
        std::cerr << "Error initializing OpenCL!" << std::endl;
        return 0;
    }

    const unsigned width = 1280;
    const unsigned height = 720;

    sf::RenderWindow window(sf::VideoMode(width, height), "Some Funky Title");

    sf::Texture texture;
    texture.create(width, height);

    uint32_t* buffer = new uint32_t[width * height];
    memset(buffer, 0, sizeof(uint32_t) * width * height);

    cl::ImageFormat format(CL_RGBA, CL_UNSIGNED_INT8);
    cl::Image2D image(context::context, CL_MEM_WRITE_ONLY, format, width, height, 0, nullptr);

    cl::Kernel kernel(context::program, "process");
    kernel.setArg(0, image);

    cl::CommandQueue queue(context::context, context::device);
    queue.enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(width, height), cl::NullRange);

    queue.enqueueReadImage(image, CL_TRUE, {0, 0, 0}, {width, height, 1}, 0, 0, buffer);

    texture.update(reinterpret_cast<unsigned char*>(buffer));

    sf::Sprite sprite(texture);
    window.draw(sprite);
    window.display();

    getchar();

    delete buffer;

    return 0;
}