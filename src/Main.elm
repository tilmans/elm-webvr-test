port module Main exposing (main)

{-
   Rotating triangle, that is a "hello world" of the WebGL
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Json.Decode exposing (Value)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import WebGL exposing (Mesh, Shader)


port updateVRCanvas : (( Float, Float ) -> msg) -> Sub msg


type alias Model =
    { time : Float, width : Int, height : Int }


type Msg
    = CanvasUpdate ( Float, Float )
    | AnimationDelta Float


main : Program Value Model Msg
main =
    Browser.element
        { init = \_ -> ( Model 0 400 400, Cmd.none )
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationDelta f ->
            ( { model | time = model.time + f }, Cmd.none )

        CanvasUpdate ( width, height ) ->
            ( { model | width = floor width, height = floor height }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ onAnimationFrameDelta AnimationDelta, updateVRCanvas CanvasUpdate ]


view : Model -> Html msg
view model =
    WebGL.toHtml
        [ width model.width
        , height model.height
        , style "display" "block"
        ]
        [ WebGL.entity
            vertexShader
            fragmentShader
            mesh
            { perspective = perspective (model.time / 1000) }
        ]


perspective : Float -> Mat4
perspective t =
    Mat4.mul
        (Mat4.makePerspective 45 1 0.01 100)
        (Mat4.makeLookAt (vec3 (4 * cos t) 0 (4 * sin t)) (vec3 0 0 0) (vec3 0 1 0))



-- Mesh


type alias Vertex =
    { position : Vec3
    , color : Vec3
    }


mesh : Mesh Vertex
mesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 1 1 0) (vec3 0 1 0)
          , Vertex (vec3 1 -1 0) (vec3 0 0 1)
          )
        ]



-- Shaders


type alias Uniforms =
    { perspective : Mat4 }


vertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        varying vec3 vcolor;
        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
        }
    |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vcolor;
        void main () {
            gl_FragColor = vec4(vcolor, 1.0);
        }
    |]