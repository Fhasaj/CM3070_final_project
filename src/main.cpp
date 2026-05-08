#include <opencv2/opencv.hpp>
#include <iostream>

//Basic install and functional test from https://www.geeksforgeeks.org/installation-guide/how-to-install-opencv-in-c-on-linux/
//& https://docs.opencv.org/4.x/db/df5/tutorial_linux_gcc_cmake.html


//TODO: REMOVE THIS AS IT CAN CAUSE ISSUES WHEN I HAVE THOUSANDS LINES OF CODE.
// Adding this for just an initial to quickly build the test application,
using namespace cv;
using namespace std;

int main(int argc, char** argv) {

    if (argc != 2) {
        cout << "Usage: DisplayImage.out <Image_Path>" << endl;
    }

    //Creates a OpenCV matrix called image in which we can use for said image.
    Mat image;

    //This matrix is then used with imread toi read the imaged passed to it in the argument when running the program
    image = imread(argv[1], 1);

    //If statement to check incase there is no image passed
    if (!image.data) {
        cout << "No image data" << endl;
        return -1;
    }

    namedWindow("Display Image", WINDOW_AUTOSIZE);
    imshow("Display Image", image);
    waitKey(0);
    return 0;

}