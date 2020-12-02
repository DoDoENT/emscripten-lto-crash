
#include <gtest/gtest.h>

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>

TEST( GTestTest, LoadRandomImage )
{
    cv::Mat img = cv::imread( "blabla.png" );
    EXPECT_TRUE( img.empty() );
}
