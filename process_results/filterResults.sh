# !/bin/bash

# remove 0.0 versions ( unknow version code)
# find aux_test_results_dir/ -name "0.0" -type d | xargs rm -rf 


# remove unwanted files from extracted results

find pc1GDResults -type d -name "unpacked" | xargs rm -rf 
find pc1GDResults -type f -name "catlog*" | xargs rm -rf 
