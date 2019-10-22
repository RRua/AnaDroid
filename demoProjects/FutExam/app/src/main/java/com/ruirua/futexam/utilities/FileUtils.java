package com.ruirua.futexam.utilities;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;

/**
 * Created by ruirua on 02/08/2019.
 */

public class FileUtils {
    public static void copyFile(File source, File dest) throws IOException {
        FileChannel sourceChannel = null;
        FileChannel destChannel = null;
        try {
            sourceChannel = new FileInputStream(source).getChannel();
            destChannel = new FileOutputStream(dest).getChannel();
            destChannel.transferFrom(sourceChannel, 0, sourceChannel.size());
        } catch (IOException e) {
        } finally {
            try {
                if (sourceChannel != null)
                    sourceChannel.close();
                if (destChannel != null)
                    destChannel.close();
            } catch (IOException e) {
            }

        }
    }
}
