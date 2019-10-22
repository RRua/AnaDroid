package com.ruirua.futexam.utilities;

/**
 * Created by ruirua on 02/08/2019.
 */

public class Constants {

    public static final int QUESTION_VALUE=5;

    public static final int HINT_PRICE = QUESTION_VALUE * 2;

    public static final int FULL_QUESTION_PRICE=QUESTION_VALUE * 3;

    public static final int fiftyfifty = QUESTION_VALUE * 2;







    public static int getTotalQuestionValue (int difficulty ){
        return QUESTION_VALUE * difficulty;
    }
}
