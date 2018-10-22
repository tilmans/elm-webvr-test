port module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Json.Decode exposing (Value)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import WebGL exposing (Mesh, Shader)


port enterVR : () -> Cmd msg


port newVRData : (VRData -> msg) -> Sub msg


type alias M4Record =
    { m11 : Float
    , m21 : Float
    , m31 : Float
    , m41 : Float
    , m12 : Float
    , m22 : Float
    , m32 : Float
    , m42 : Float
    , m13 : Float
    , m23 : Float
    , m33 : Float
    , m43 : Float
    , m14 : Float
    , m24 : Float
    , m34 : Float
    , m44 : Float
    }


type alias VRData =
    { leftProjectionMatrix : M4Record
    , leftViewMatrix : M4Record
    , rightProjectionMatrix : M4Record
    , rightViewMatrix : M4Record
    }


type alias Model =
    { time : Float
    , width : Int
    , height : Int
    , initialised : Bool
    , leftProjection : Mat4
    , leftView : Mat4
    }


type Msg
    = CanvasUpdate ( Float, Float )
    | NewVRData VRData
    | AnimationDelta Float


main : Program Value Model Msg
main =
    Browser.element
        { init = \_ -> ( Model 4500 400 400 False Mat4.identity Mat4.identity, Cmd.none )
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationDelta f ->
            if model.initialised then
                ( model, Cmd.none )

            else
                ( { model | initialised = True }, enterVR () )

        CanvasUpdate ( width, height ) ->
            ( { model | width = floor width, height = floor height }, Cmd.none )

        NewVRData data ->
            ( { model
                | leftProjection = Mat4.fromRecord data.leftProjectionMatrix
                , leftView = Mat4.fromRecord data.leftViewMatrix
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.initialised then
            Sub.none

          else
            onAnimationFrameDelta AnimationDelta
        , newVRData NewVRData
        ]


view : Model -> Html msg
view model =
    let
        dynamic =
            Mat4.mul model.leftProjection model.leftView

        static =
            Mat4.mul
                (Mat4.makePerspective 45 1 0.01 100)
                (Mat4.makeLookAt (vec3 0 0 -5) (vec3 0 0 0) (vec3 0 1 0))
    in
    WebGL.toHtml
        [ width 400
        , height 400
        , style "display" "block"
        ]
        [ WebGL.entity
            vertexShader
            fragmentShader
            mesh
            { perspective = static }
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
        [ ( Vertex (vec3 -5 -5 1) (vec3 1 0 0)
          , Vertex (vec3 5 -5 1) (vec3 0 1 0)
          , Vertex (vec3 5 5 1) (vec3 0 0 1)
          )
        , ( Vertex (vec3 5 5 1) (vec3 1 0 0)
          , Vertex (vec3 -5 5 1) (vec3 0 1 0)
          , Vertex (vec3 -5 -5 1) (vec3 0 0 1)
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
