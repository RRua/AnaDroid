package com.ruirua.futexam.ui.activities;

import android.content.Intent;
import android.support.annotation.Nullable;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.widget.Button;

import com.ruirua.futexam.R;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class MenuActivity extends AppCompatActivity{

    @BindView(R.id.menuButton1)
    Button buttonStartExam;
    @BindView(R.id.menuButton2)
    Button buttonChooseCategory;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main_menu);
        ButterKnife.bind(this);
    }

    @OnClick(R.id.menuButton1)
    void onClick(){
        Intent intent = new Intent( this,QuestionActivity.class);
        startActivity(intent);
    }

    @OnClick(R.id.menuButton2)
    void onClick2(){
        Intent intent = new Intent( this,ItemListActivity.class);
        startActivity(intent);
    }

}
