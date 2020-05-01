module Main exposing (main)

import Browser
import Html exposing (Html, text, div)
import Html.Attributes exposing (style, placeholder)
import Html.Events exposing (onInput)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Dict exposing (Dict)
import Chart



-- MAIN


main =
  Browser.document
    { init = init
    , update = update
    , subscriptions = \_ -> Sub.none
    , view = \model -> { title = "News Classification JUGA", body = [ view model ] }
    }



-- MODEL


type Model
  = Failure String
  | Loading
  | Success PredictionResult


type alias PredictionResult = {
        predictions: Dict String Float
        , bestClass: String
    }

decodePrediction : JD.Decoder PredictionResult
decodePrediction = JD.map2 PredictionResult
    (JD.at ["predictions"] (JD.dict JD.float))
    (JD.at ["bestClass"] JD.string)
    

init : () -> (Model, Cmd Msg)
init _ =
  ( Loading
  , Cmd.none
  )

body : String -> JE.Value
body newsLine =
    JE.object [( "newsLine", JE.string newsLine )  ]

runClassification: String -> Cmd Msg
runClassification newsLine = Http.post {
    url = "/nlpclass/news-category/prediction"
    , body = Http.jsonBody (body newsLine)
    , expect = Http.expectJson GotText decodePrediction
    }

-- UPDATE


type Msg
  =
  RunNewsClassification String |
  GotText (Result Http.Error PredictionResult)



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    RunNewsClassification newsLine ->
        (Loading, runClassification newsLine)
    GotText result ->
      case result of
        Ok fullText ->
          (Success fullText, Cmd.none)

        Err error ->
            let
                errorText = Debug.toString error
            in
            (Failure errorText, Cmd.none)



-- VIEW


view : Model -> Html Msg
view model =
    div [style "margin" "100px"] [
        div [] [ Html.input [ placeholder "Enter News Headline ...", style "width" "100%", style "font-size" "large", onInput RunNewsClassification ] [] ]
        , div [style "height" "20px"] []
        , div [] [viewData model]
    ]



viewData : Model -> Html Msg
viewData model =
  case model of
    Failure errorText ->
      text <| "Unable to run prediction: " ++ errorText

    Loading ->
      div [] [text "Calling..."]

    Success predictionResult ->
      div [] [
        Dict.toList predictionResult.predictions |> viewChart
        , text ("bestClass: " ++ predictionResult.bestClass)]


viewChart : List (String, Float) -> Html msg
viewChart predictions = 
    let
        scaled = List.map (\(category, value) -> (category, value)) predictions
    in
        Chart.view scaled
