package com.ruirua.futexam.ui.activities;

import android.arch.lifecycle.Observer;
import android.arch.lifecycle.ViewModelProviders;
import android.support.annotation.Nullable;
import android.support.constraint.ConstraintLayout;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.ruirua.futexam.R;
import com.ruirua.futexam.database.models.Question;
import com.ruirua.futexam.database.models.User;
import com.ruirua.futexam.ui.viewmodels.QuestionViewModel;
import com.ruirua.futexam.utilities.Constants;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import de.hdodenhof.circleimageview.CircleImageView;

public class QuestionActivity extends AppCompatActivity {

    public static final String TAG = QuestionActivity.class.getSimpleName();

    private QuestionViewModel questionViewModel;

    @BindView(R.id.tvpoints)
    TextView pointsView;
    @BindView(R.id.tv_friends)
    TextView friendsView;
    @BindView(R.id.tv_coins)
    TextView coinsView;


    @BindView(R.id.question_text_view)
    TextView textViewQuestion;
    @BindView(R.id.question_image)
    CircleImageView circleImageViewQuestion;
    @BindView(R.id.button_hint)
    Button buttonQuestionHint;
    @BindView(R.id.button_buy_question)
    Button buttonBuyQuestion;
    @BindView(R.id.button_collapse_alternative)
    Button button5050;
    @BindView(R.id.buttonTopLeft)
    Button buttonTopLeft;
    @BindView(R.id.buttonTopRight)
    Button buttonTopRigh;
    @BindView(R.id.button_bottom_left)
    Button buttonBottomLeft;
    @BindView(R.id.button_bottom_right)
    Button buttonBottomRight;
    @BindView(R.id.question_constraint_layout)
    ConstraintLayout constraintLayout;

    Map<Integer,Question> questionList = new HashMap<>();
    List<Question> answeredQuestions = new ArrayList<>();

    private Question actualQuestion = null;



    @OnClick({R.id.button_bottom_left,R.id.button_bottom_right, R.id.buttonTopLeft, R.id.buttonTopRight})
    void onClickAnswerButton(View v){
        if (v instanceof Button){
            String userAnswer =  ((Button) v).getText().toString();
            if (userAnswer.equals(actualQuestion.getAnswer())){
                //answer is right
               handleRightAnswer();
            }
            else {
                //((Button) v).setBackgroundColor(getResources().getColor(R.color.colorGrey));
            }
        }

        actualQuestion = loadRandomQuestion();
        setQuestionView();
    }

    @OnClick({R.id.button_hint, R.id.button_buy_question, R.id.button_collapse_alternative})
    void onClickHelpButtons(View v){
        // get coins TODO
        int actualUserCoins =  questionViewModel.currentUser.getValue().getCoins();
        if (v.getId() == R.id.button_hint && actualUserCoins > Constants.fiftyfifty ){
            //subtract points
            // actualUserCoins - Constants.fiftyfifty;
            questionViewModel.currentUser.getValue().setCoins(actualUserCoins - Constants.fiftyfifty);
            // coinsView.setText("Coins:" + actualUserCoins);
            hideButtons(2);

        }
        else if (v.getId() == R.id.button_collapse_alternative && actualUserCoins > Constants.HINT_PRICE ) {
            questionViewModel.currentUser.getValue().setCoins(actualUserCoins - Constants.HINT_PRICE);
            hideButtons(1);

        }
        else if (v.getId() == R.id.button_buy_question && actualUserCoins > Constants.FULL_QUESTION_PRICE ) {
            questionViewModel.currentUser.getValue().setCoins(actualUserCoins - Constants.FULL_QUESTION_PRICE);
            handleRightAnswer();
        }
    }

    private void hideButtons(int nrButtonsToHide) {
        if (nrButtonsToHide<=0){
            return;
        }
        // TODO Randomize this
        // if is visible and is not the answer
        else if (buttonBottomLeft.getVisibility() == View.VISIBLE && ( ! buttonBottomLeft.getText().equals(actualQuestion.getAnswer()) ) ){
            buttonBottomLeft.setVisibility(View.INVISIBLE);
            hideButtons(--nrButtonsToHide);
        }
        else if (buttonTopRigh.getVisibility() == View.VISIBLE && ( ! buttonTopRigh.getText().equals(actualQuestion.getAnswer()) ) ){
            buttonTopRigh.setVisibility(View.INVISIBLE);
            hideButtons(--nrButtonsToHide);
        }
        else if (buttonBottomRight.getVisibility() == View.VISIBLE && ( ! buttonBottomRight.getText().equals(actualQuestion.getAnswer()) ) ){
            buttonBottomRight.setVisibility(View.INVISIBLE);
            hideButtons(--nrButtonsToHide);
        }
        else if (buttonTopLeft.getVisibility() == View.VISIBLE && ( ! buttonTopLeft.getText().equals(actualQuestion.getAnswer()) ) ){
            buttonTopLeft.setVisibility(View.INVISIBLE);
            hideButtons(--nrButtonsToHide);
        }
    }

    void handleRightAnswer(){
        int actualUserPoints = questionViewModel.currentUser.getValue().getPoints();
        questionViewModel.currentUser.getValue().setPoints(actualUserPoints + Constants.getTotalQuestionValue(actualQuestion.getDifficulty()));

        //Integer.parseInt( pointsView.getText().toString().split(":")[1]);
       // pointsView.setText("Points:" + ( actualUserPoints + Constants.getTotalQuestionValue(actualQuestion.getDifficulty())));
        Snackbar snackbar = Snackbar.make(constraintLayout,"+" + Constants.getTotalQuestionValue(actualQuestion.getDifficulty()) +" points" ,Snackbar.LENGTH_SHORT);
        snackbar.show();
        actualQuestion.setAnswered(true);
        answeredQuestions.add(actualQuestion);
    }



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_question);
        ButterKnife.bind(this);
        initViewModel();
        addSampleData();
        for (Question x : questionViewModel.loadAllQuestionsSimple()) {
            questionList.put(x.getId(), x);
        }
        actualQuestion =  loadRandomQuestion();
        setQuestionView();

    }

    private void setQuestionView() {
        if (actualQuestion!=null){
            List<String> l = new ArrayList<>();
            l.add(actualQuestion.getAnswer());
            l.add(actualQuestion.getAlternative1());
            l.add(actualQuestion.getAlternative2());
            l.add(actualQuestion.getAlternative3());
            Collections.shuffle(l);

            buttonTopLeft.setText(l.get(0));
            buttonTopLeft.setVisibility(View.VISIBLE);

            buttonTopRigh.setText(l.get(1));
            buttonTopRigh.setVisibility(View.VISIBLE);

            buttonBottomLeft.setText(l.get(2));
            buttonBottomLeft.setVisibility(View.VISIBLE);

            buttonBottomRight.setText(l.get(3));
            buttonBottomRight.setVisibility(View.VISIBLE);

            textViewQuestion.setText(actualQuestion.getQuestion());
            circleImageViewQuestion.setImageBitmap( questionViewModel.getImageById((actualQuestion.getImg_id())) );
            questionList.remove(actualQuestion.getId());
        }
    }



    private void initViewModel() {
        final Observer<List<Question>> observer = new Observer<List<Question>>() {
            @Override
            public void onChanged(@Nullable List<Question> questions) {
                questionList.clear();
                for (Question x :questions) {
                    questionList.put(x.getId(), x);
                }
            }
        };

        questionViewModel = ViewModelProviders.of(this).get(QuestionViewModel.class);
        questionViewModel.questions .observe(this, observer);

        questionViewModel.currentUser.observe(this, new Observer<User>() {
            @Override
            public void onChanged(@Nullable User user) {
                coinsView.setText("Coins:" + user.getCoins());
                pointsView.setText("Points:" + user.getPoints());
                questionViewModel.currentUser.getValue().setCoins(user.getCoins());
                questionViewModel.currentUser.getValue().setPoints(user.getPoints());
                System.out.println("update user");
            }
        });
    }




    private void addSampleData() {
        questionViewModel.addSampleData(getResources());
    }

    private Question loadRandomQuestion(){
        if ( questionList!=null && ! questionList.isEmpty() ){
            List<Question> list = new ArrayList<>();
            list.addAll(questionList.values());
            Collections.shuffle(list);
            return list.get(0);
        }
        else {
            endOfQuiz();
            return null;
        }
    }

    private void endOfQuiz() {
        finish();
    }

    @Override
    protected void onStop() {
        questionViewModel.addQuestions(answeredQuestions);
        questionViewModel.setUser(questionViewModel.currentUser);
        super.onStop();
    }
}
