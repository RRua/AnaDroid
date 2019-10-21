package com.ruirua.futexam.utilities;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.ruirua.futexam.R;
import com.ruirua.futexam.database.models.Category;
import com.ruirua.futexam.database.models.Image;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.database.models.User;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Created by ruirua on 02/08/2019.
 */

public class SampleData {

    public static List<Image> getSampleImages(Resources res){
        ArrayList<Image> ret =  new ArrayList<Image>();
        ret.add( new Image(1,
                    Image.toByteArray(
                            BitmapFactory.decodeResource(res, R.mipmap.questionmark )
                    )
                )
        );
        ret.add( new Image(2,
                        Image.toByteArray(
                                BitmapFactory.decodeResource(res, R.mipmap.nakajima )
                        )
                )
        );
        ret.add( new Image(3,
                        Image.toByteArray(
                                BitmapFactory.decodeResource(res, R.mipmap.marega )
                        )
                )
        );
        ret.add( new Image(4,
                        Image.toByteArray(
                                BitmapFactory.decodeResource(res, R.mipmap.derrossi )
                        )
                )
        );
        return ret;
    }


    public static List<Question> getSampleQuestions(){
        ArrayList<Question> ret =  new ArrayList<Question>();
        Random r = new Random();
        ret.add( new Question(
                "Quem é este jogador japonês?",
                "Nakajima",
                "Takashi Inui",
                "Zé Luis",
                "Kubo",
                2,
                new Category( Category.CategoryDesignation.PLAYER)
        ));
        ret.add( new Question(
                "Quem é este jogador?",
                "Marega",
                "Aboubakar",
                "Danilo",
                "Brahimi",
                3,
                new Category( Category.CategoryDesignation.PLAYER)
        ));
        ret.add( new Question(
                "Que clube De Rossi escolheu para terminar carreira?",
                "Boca Juniors",
                "San Lorenzo",
                "Vélez",
                "River Plate",
                4,
                new Category( Category.CategoryDesignation.PLAYER)
        ));

        ret.add( new Question(
                "Quem foi o vencedor da última edição da 2ª Liga Portuguesa?",
                "Paços de Ferreira",
                "Famalicão",
                "Estoril",
                "Gil Vicente",
                1,
                new Category( Category.CategoryDesignation.CLUB)
        ));
        ret.add( new Question(
                "Qual a nacionalidade de Moussa Marega?",
                "Mali",
                "Camarões",
                "Senegal",
                "Nigéria",
                3,
                new Category( Category.CategoryDesignation.PLAYER)
        ));
        ret.add( new Question(
                "Nakajima assinou em 2019 pelo FC Porto. Qual o seu clube anterior?",
                "Al-Duhail",
                "Kataller Toyama",
                "Portimonense",
                "Al-Rayan",
                2,
                new Category( Category.CategoryDesignation.PLAYER)
        ));

        return ret;
    }

    public static User getUser(Resources res){
        return new User(1,"elMagoNakajima", 10,20,  Image.toByteArray(
                BitmapFactory.decodeResource(res, R.mipmap.marega )
        ) );
    }


    public static List<Category> getSampleCategories(){
        ArrayList<Category> ret =  new ArrayList<Category>();
        Random r = new Random();
        for ( Category.CategoryDesignation cat :Category.CategoryDesignation.values()){
            ret.add(new Category( cat.getCode(), cat ));
        }
        return ret;
    }
}
