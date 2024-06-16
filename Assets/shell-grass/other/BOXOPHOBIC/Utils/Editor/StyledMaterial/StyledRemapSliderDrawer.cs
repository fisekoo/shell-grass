// Cristian Pop - https://boxophobic.com/

using UnityEngine;
using UnityEditor;
using System;

public class StyledRemapSliderDrawer : MaterialPropertyDrawer
{
    public string nameMin = "";
    public string nameMax = "";
    public float min = 0;
    public float max = 0;
    public float top = 0;
    public float down = 0;

    float internalValueMin;
    float internalValueMax;

    bool showAdvancedOptions = false;

    public StyledRemapSliderDrawer(string nameMin, string nameMax, float min, float max)
    {
        this.nameMin = nameMin;
        this.nameMax = nameMax;
        this.min = min;
        this.max = max;
        this.top = 0;
        this.down = 0;
    }

    public StyledRemapSliderDrawer(string nameMin, string nameMax, float min, float max, float top, float down)
    {
        this.nameMin = nameMin;
        this.nameMax = nameMax;
        this.min = min;
        this.max = max;
        this.top = top;
        this.down = down;
    }

    public StyledRemapSliderDrawer()
    {
        this.nameMin = null;
        this.nameMax = null;
        this.min = 0;
        this.max = 1;
        this.top = 0;
        this.down = 0;
    }

    public StyledRemapSliderDrawer(float min, float max)
    {
        this.nameMin = null;
        this.nameMax = null;
        this.min = min;
        this.max = max;
        this.top = 0;
        this.down = 0;
    }

    public StyledRemapSliderDrawer(float min, float max, float top, float down)
    {
        this.nameMin = null;
        this.nameMax = null;
        this.min = min;
        this.max = max;
        this.top = top;
        this.down = down;
    }

    public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor)
    {
        var internalPropMin = MaterialEditor.GetMaterialProperty(editor.targets, nameMin);
        var internalPropMax = MaterialEditor.GetMaterialProperty(editor.targets, nameMax);

        var stylePopupMini = new GUIStyle(EditorStyles.popup)
        {
            fontSize = 9,
        };

        var styleButton = new GUIStyle(EditorStyles.label)
        {

        };

        Vector4 propVector = prop.vectorValue;

        EditorGUI.BeginChangeCheck();

        if (propVector.w == 0)
        {
            internalValueMin = propVector.x;
            internalValueMax = propVector.y;
        }
        else
        {
            internalValueMin = propVector.y;
            internalValueMax = propVector.x;
        }

        GUILayout.Space(top);

        EditorGUI.showMixedValue = prop.hasMixedValue;

        GUILayout.BeginHorizontal();

        if (GUILayout.Button(label, styleButton, GUILayout.Width(EditorGUIUtility.labelWidth), GUILayout.Height(18)))
        {
            showAdvancedOptions = !showAdvancedOptions;
        }

        EditorGUILayout.MinMaxSlider(ref internalValueMin, ref internalValueMax, min, max);

        GUILayout.Space(2);

        propVector.w = (float)EditorGUILayout.Popup((int)propVector.w, new string[] { "Remap", "Invert" }, stylePopupMini, GUILayout.Width(50));

        GUILayout.EndHorizontal();

        if (showAdvancedOptions)
        {
            GUILayout.BeginHorizontal();
            GUILayout.Space(-1);
            GUILayout.Label("      Remap Min", GUILayout.Width(EditorGUIUtility.labelWidth));
            internalValueMin = Mathf.Clamp(EditorGUILayout.Slider(internalValueMin, min, max), min, internalValueMax);
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            GUILayout.Space(-1);
            GUILayout.Label("      Remap Max", GUILayout.Width(EditorGUIUtility.labelWidth));
            internalValueMax = Mathf.Clamp(EditorGUILayout.Slider(internalValueMax, min, max), internalValueMin, max);
            GUILayout.EndHorizontal();
        }

        EditorGUI.showMixedValue = false;

        if (EditorGUI.EndChangeCheck())
        {
            if (propVector.w == 0)
            {
                propVector.x = internalValueMin;
                propVector.y = internalValueMax;
            }
            else
            {
                propVector.y = internalValueMin;
                propVector.x = internalValueMax;
            }

            prop.vectorValue = propVector;

            if (internalPropMin.displayName != null && internalPropMax.displayName != null)
            {
                internalPropMin.floatValue = internalValueMin;
                internalPropMax.floatValue = internalValueMax;
            }
        }

        GUILayout.Space(down);
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return -2;
    }
}