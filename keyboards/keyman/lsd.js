
KeymanWeb.KR(new Keyboard_lsd());

function Keyboard_lsd()
{
  
  this.KI="Keyboard_lsd";
  this.KN="LisanFlexible";
  this.KMINVER="9.0";
  this.KV={F:' 1em "FatemiMaqala"',K102:0};
  this.KV.KLS={
    "default": ["ذ","1","2","3","4","5","6","7","8","9","0","-","=","","","","ض","ص","ث","ق","ف","غ","ع","ه","خ","ح","ج","د","\\","","","","ش","س","ي","ب","ل","ا","ت","ن","م","ك","ط","","","","","","","ئ","ء","ؤ","ر","ال","ى","ة","و","ز","ظ","","","","","",""],
    "shift": ["ّ","!","@","#","$","%",">","<","۞",")","(","","+","","","","َ","ُ","ٗ","ؕ","ڤ","إ","ژ","ھ","ہ","چھے","چ","]","[","","","","ِ","","ے","پ","اٰ","أ","ـ","،","ں","گ","\"","","","","","","","ٓ","ْ","ۚ","ۨ","٬","آ","ۃ","/",".","؟","","","","","",""]
  };
  this.KV.BK=(function(x){
    var
      empty=Array.apply(null, Array(65)).map(String.prototype.valueOf,""),
      result=[], v, i,
      modifiers=['default','shift','ctrl','shift-ctrl','alt','shift-alt','ctrl-alt','shift-ctrl-alt'];
    for(i=modifiers.length-1;i>=0;i--) {
      v = x[modifiers[i]];
      if(v || result.length > 0) {
        result=(v ? v : empty).slice().concat(result);
      }
    }
    return result;
  })(this.KV.KLS);
  this.KDU=1;
  this.KH='';
  this.KM=0;
  this.KBVER="1.0";
  this.KMBM=0x0010;
  this.KRTL=1;
  this.KVKD="T_SAW T_SA T_AS T_RA T_TUS T_QR T_RH T_B T_BH T_BHS T_BHHS T_Kzabr T_KZer T_Maddah T_Semi T_SingQuote T_goalHamza T_Laa T_LaaU T_LaaD T_LaaK T_LaaM T_Rreh T_Ddeh T_Tteh T_Ara0 T_Ara1 T_Ara2 T_Ara3 T_Ara4 T_Ara5 T_Ara6 T_Ara7 T_Ara8 T_Ara9 T_Guj0 T_Guj1 T_Guj2 T_Guj3 T_Guj4 T_Guj5 T_Guj6 T_Guj7 T_Guj8 T_Guj9 T_Afghani T_Yen T_Ray T_GujRup T_Rupee T_mult T_divide T_asterisk T_fivepoint T_Caret T_zwj T_zwnj T_Sanah T_Samvat T_Footnote T_Safha T_poetry T_Number T_Takhallus T_Misra T_Ayah T_Sajda T_arabPercent";
  this.KVKL={
  "phone": {
    "font": "FatemiMaqala",
    "layer": [
      {
        "id": "default",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_Q",
                "text": "ض"
              },
              {
                "id": "K_W",
                "text": "ص"
              },
              {
                "id": "K_E",
                "text": "ث"
              },
              {
                "id": "K_R",
                "text": "ق"
              },
              {
                "id": "K_T",
                "text": "ف"
              },
              {
                "id": "K_Y",
                "text": "غ"
              },
              {
                "id": "K_U",
                "text": "ع"
              },
              {
                "id": "K_I",
                "text": "ه",
                "sk": [
                  {
                    "text": "ـہـ",
                    "id": "K_O",
                    "layer": "shift"
                  },
                  {
                    "text": "ـہ",
                    "id": "K_O",
                    "layer": "shift"
                  },
                  {
                    "text": "ھ",
                    "id": "K_I",
                    "layer": "shift"
                  },
                  {
                    "text": "ة",
                    "id": "K_M"
                  },
                  {
                    "text": "ۂ",
                    "id": "T_goalHamza"
                  }
                ]
              },
              {
                "id": "K_O",
                "text": "خ"
              },
              {
                "id": "K_P",
                "text": "ح"
              },
              {
                "id": "K_LBRKT",
                "text": "ج",
                "sk": [
                  {
                    "text": "چ",
                    "id": "K_LBRKT",
                    "layer": "shift"
                  },
                  {
                    "text": "چھے",
                    "id": "K_P",
                    "layer": "shift"
                  }
                ]
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_A",
                "text": "ش",
                "pad": "40"
              },
              {
                "id": "K_S",
                "text": "س"
              },
              {
                "id": "K_D",
                "text": "ي",
                "sk": [
                  {
                    "text": "ئ",
                    "id": "K_Z"
                  },
                  {
                    "text": "ى",
                    "id": "K_N"
                  },
                  {
                    "text": "ے",
                    "id": "K_D",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_F",
                "text": "ب"
              },
              {
                "id": "K_G",
                "text": "ل",
                "sk": [
                  {
                    "text": "لا",
                    "id": "T_Laa"
                  },
                  {
                    "text": "لأ",
                    "id": "T_LaaU"
                  },
                  {
                    "text": "لإ",
                    "id": "T_LaaD"
                  },
                  {
                    "text": "لآ",
                    "id": "T_LaaM"
                  },
                  {
                    "text": "لاٰ",
                    "id": "T_LaaK"
                  }
                ]
              },
              {
                "id": "K_H",
                "text": "ا",
                "sk": [
                  {
                    "text": "أ",
                    "id": "K_H",
                    "layer": "shift"
                  },
                  {
                    "text": "إ",
                    "id": "K_Y",
                    "layer": "shift"
                  },
                  {
                    "text": "آ",
                    "id": "K_N",
                    "layer": "shift"
                  },
                  {
                    "text": "اٰ",
                    "id": "K_G",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_J",
                "text": "ت"
              },
              {
                "id": "K_K",
                "text": "ن"
              },
              {
                "id": "K_L",
                "text": "م",
                "pad": ""
              },
              {
                "id": "K_COLON",
                "text": "ك",
                "width": "",
                "sk": [
                  {
                    "text": "گ",
                    "id": "K_COLON",
                    "layer": "shift"
                  }
                ]
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_SHIFT",
                "text": "*Shift*",
                "width": "150",
                "sp": "1",
                "nextlayer": "shift"
              },
              {
                "id": "K_BKQUOTE",
                "text": "ذ",
                "pad": ""
              },
              {
                "id": "K_SLASH",
                "text": "ظ"
              },
              {
                "id": "K_C",
                "text": "ؤ"
              },
              {
                "id": "K_V",
                "text": "ر",
                "sk": [
                  {
                    "text": "ڑ",
                    "id": "T_Rreh"
                  }
                ]
              },
              {
                "id": "K_PERIOD",
                "text": "ز"
              },
              {
                "id": "K_COMMA",
                "text": "و"
              },
              {
                "id": "K_QUOTE",
                "text": "ط",
                "nextlayer": "default"
              },
              {
                "id": "K_RBRKT",
                "text": "د",
                "sk": [
                  {
                    "text": "ڈ",
                    "id": "T_Ddeh"
                  }
                ]
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "width": "150",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_NUMLOCK",
                "text": "*123*",
                "width": "120",
                "sp": "1",
                "nextlayer": "numeric"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "100",
                "sp": "1"
              },
              {
                "id": "K_N",
                "text": "ى"
              },
              {
                "id": "K_HELP",
                "text": "اعراب",
                "width": "120",
                "nextlayer": "default",
                "sk": [
                  {
                    "text": "زبر",
                    "id": "K_Q",
                    "layer": "shift"
                  },
                  {
                    "text": "زير",
                    "id": "K_A",
                    "layer": "shift"
                  },
                  {
                    "text": "پيش",
                    "id": "K_W",
                    "layer": "shift"
                  },
                  {
                    "text": "جزم",
                    "id": "K_X",
                    "layer": "shift"
                  },
                  {
                    "text": "~",
                    "id": "T_Maddah"
                  }
                ]
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "325",
                "sp": "1"
              },
              {
                "id": "K_PERIOD",
                "text": ".",
                "width": "100",
                "layer": "shift",
                "sk": [
                  {
                    "text": ".",
                    "id": "K_PERIOD",
                    "layer": "shift"
                  },
                  {
                    "text": "!",
                    "id": "k_1",
                    "layer": "shift"
                  },
                  {
                    "text": "؟",
                    "id": "K_SLASH",
                    "layer": "shift"
                  },
                  {
                    "text": "،",
                    "id": "K_K",
                    "layer": "shift"
                  },
                  {
                    "text": "؛",
                    "id": "T_Semi"
                  },
                  {
                    "text": "/",
                    "id": "K_COMMA",
                    "layer": "shift"
                  },
                  {
                    "text": "\\",
                    "id": "K_BKSLASH"
                  },
                  {
                    "text": "\"",
                    "id": "K_QUOTE",
                    "layer": "shift"
                  },
                  {
                    "text": "'",
                    "id": "T_SingQuote"
                  },
                  {
                    "text": "٬",
                    "id": "K_B",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_X",
                "text": "ء"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      },
      {
        "id": "shift",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_Q",
                "text": "ـَ"
              },
              {
                "id": "K_W",
                "text": "ـُ"
              },
              {
                "id": "K_E",
                "text": "ـٗ"
              },
              {
                "id": "K_R",
                "text": "ـؕ"
              },
              {
                "id": "T_SAW",
                "text": "ـؐ",
                "layer": "default"
              },
              {
                "id": "T_AS",
                "text": "ـؑ",
                "layer": "default"
              },
              {
                "id": "T_SA",
                "text": "ـ",
                "layer": "default"
              },
              {
                "id": "K_I",
                "text": "ھ"
              },
              {
                "id": "K_U",
                "text": "ژ"
              },
              {
                "id": "K_P",
                "text": "چھے"
              },
              {
                "id": "K_LBRKT",
                "text": "چ"
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_A",
                "text": "ـِ",
                "pad": "30"
              },
              {
                "id": "T_KZabr",
                "text": "ـٰ",
                "layer": "default"
              },
              {
                "id": "K_D",
                "text": "ے"
              },
              {
                "id": "K_F",
                "text": "پ"
              },
              {
                "id": "T_TUS",
                "text": "ـ",
                "layer": "default"
              },
              {
                "id": "T_RA",
                "text": "ـؓ",
                "layer": "default"
              },
              {
                "id": "K_J",
                "text": "ـ"
              },
              {
                "id": "K_K",
                "text": "،"
              },
              {
                "id": "K_L",
                "text": "ں"
              },
              {
                "id": "K_COLON",
                "text": "گ"
              },
              {
                "id": "T_B",
                "text": "",
                "width": "60",
                "layer": "default",
                "sk": [
                  {
                    "text": "",
                    "id": "T_B",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BH",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BHS",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BHHS",
                    "layer": "default"
                  }
                ]
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_SHIFT",
                "text": "",
                "width": "150",
                "sp": "2",
                "nextlayer": "default"
              },
              {
                "id": "K_X",
                "text": "ـْ"
              },
              {
                "id": "T_KZer",
                "text": "ـٖ",
                "layer": "default"
              },
              {
                "id": "K_C",
                "text": "ـۚ"
              },
              {
                "id": "T_Rreh",
                "text": "ڑ",
                "layer": "default"
              },
              {
                "id": "T_QR",
                "text": "",
                "layer": "default"
              },
              {
                "id": "T_RH",
                "text": "ـؒ",
                "layer": "default"
              },
              {
                "id": "T_tteh",
                "text": "ٹ",
                "layer": "default"
              },
              {
                "id": "T_ddeh",
                "text": "ڈ",
                "layer": "default"
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "width": "150",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_NUMLOCK",
                "text": "*123*",
                "width": "150",
                "sp": "1",
                "nextlayer": "numeric"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "120",
                "sp": "1"
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "610",
                "sp": "0"
              },
              {
                "id": "K_8",
                "text": "۞",
                "layer": "shift"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      },
      {
        "id": "numeric",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_1",
                "text": "1",
                "sk": [
                  {
                    "text": "١",
                    "id": "T_Ara1"
                  },
                  {
                    "text": "૧",
                    "id": "T_Guj1"
                  }
                ]
              },
              {
                "id": "K_2",
                "text": "2",
                "sk": [
                  {
                    "text": "٢",
                    "id": "T_Ara2"
                  },
                  {
                    "text": "૨",
                    "id": "T_Guj2"
                  }
                ]
              },
              {
                "id": "K_3",
                "text": "3",
                "sk": [
                  {
                    "text": "٣",
                    "id": "T_Ara3"
                  },
                  {
                    "text": "૩",
                    "id": "T_Guj3"
                  }
                ]
              },
              {
                "id": "K_4",
                "text": "4",
                "sk": [
                  {
                    "text": "٤",
                    "id": "T_Ara4"
                  },
                  {
                    "text": "૪",
                    "id": "T_Guj4"
                  }
                ]
              },
              {
                "id": "K_5",
                "text": "5",
                "sk": [
                  {
                    "text": "٥",
                    "id": "T_Ara5"
                  },
                  {
                    "text": "૫",
                    "id": "T_Guj5"
                  }
                ]
              },
              {
                "id": "K_6",
                "text": "6",
                "sk": [
                  {
                    "text": "٦",
                    "id": "T_Ara6"
                  },
                  {
                    "text": "૬",
                    "id": "T_Guj6"
                  }
                ]
              },
              {
                "id": "K_7",
                "text": "7",
                "sk": [
                  {
                    "text": "٧",
                    "id": "T_Ara7"
                  },
                  {
                    "text": "૭",
                    "id": "T_Guj7"
                  }
                ]
              },
              {
                "id": "K_8",
                "text": "8",
                "sk": [
                  {
                    "text": "٨",
                    "id": "T_Ara8"
                  },
                  {
                    "text": "૮",
                    "id": "T_Guj8"
                  }
                ]
              },
              {
                "id": "K_9",
                "text": "9",
                "sk": [
                  {
                    "text": "٩",
                    "id": "T_Ara9"
                  },
                  {
                    "text": "૯",
                    "id": "T_Guj9"
                  }
                ]
              },
              {
                "id": "K_0",
                "text": "0",
                "sk": [
                  {
                    "text": "٠",
                    "id": "T_Ara0"
                  },
                  {
                    "text": "૰",
                    "id": "T_Guj0"
                  }
                ]
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_4",
                "text": "$",
                "layer": "shift",
                "sk": [
                  {
                    "text": "₨",
                    "id": "T_Rupee"
                  },
                  {
                    "text": "¥",
                    "id": "T_Yen"
                  },
                  {
                    "text": "؋",
                    "id": "T_Afghani"
                  },
                  {
                    "text": "؈",
                    "id": "T_Ray"
                  },
                  {
                    "text": "૱",
                    "id": "T_GujRup"
                  }
                ]
              },
              {
                "id": "K_3",
                "text": "#",
                "layer": "shift"
              },
              {
                "id": "K_5",
                "text": "%",
                "layer": "shift",
                "sk": [
                  {
                    "text": "٪",
                    "id": "T_arabPercent"
                  }
                ]
              },
              {
                "id": "T_Caret",
                "text": "^"
              },
              {
                "id": "K_7",
                "text": "<",
                "layer": "shift"
              },
              {
                "id": "K_6",
                "text": ">",
                "layer": "shift"
              },
              {
                "id": "K_EQUAL",
                "text": "+",
                "layer": "shift",
                "sk": [
                  {
                    "text": "×",
                    "id": "T_mult"
                  }
                ]
              },
              {
                "id": "K_EQUAL",
                "text": "="
              },
              {
                "id": "T_Asterisk",
                "text": "*",
                "sk": [
                  {
                    "text": "٭",
                    "id": "T_fivepoint"
                  }
                ]
              },
              {
                "id": "K_HYPHEN",
                "text": "-",
                "sk": [
                  {
                    "text": "÷",
                    "id": "T_Divide"
                  },
                  {
                    "text": "_",
                    "id": "K_HYPHEN",
                    "layer": "shift"
                  }
                ]
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_2",
                "text": "@",
                "layer": "shift"
              },
              {
                "id": "K_0",
                "text": "(",
                "layer": "shift"
              },
              {
                "id": "K_9",
                "text": ")",
                "layer": "shift"
              },
              {
                "id": "T_Misra",
                "text": "؏"
              },
              {
                "id": "T_Takhallus",
                "text": "ؔ"
              },
              {
                "id": "T_Safha",
                "text": "؃"
              },
              {
                "id": "T_Footnote",
                "text": "؂",
                "sk": [
                  {
                    "text": "؎",
                    "id": "T_poetry"
                  }
                ]
              },
              {
                "id": "T_Sanah",
                "text": "؁",
                "sk": [
                  {
                    "text": "؄",
                    "id": "T_Samvat"
                  }
                ]
              },
              {
                "id": "T_Number",
                "text": "؀",
                "sk": [
                  {
                    "text": "۝",
                    "id": "T_Ayah"
                  },
                  {
                    "text": "۩",
                    "id": "T_Sajda"
                  }
                ]
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_LOWER",
                "text": "*abc*",
                "width": "150",
                "sp": "1",
                "nextlayer": "default"
              },
              {
                "id": "K_S",
                "text": "mod",
                "layer": "shift"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "120",
                "sp": "1"
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "500",
                "sp": "0"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      }
    ],
    "displayUnderlying": false
  },
  "tablet": {
    "font": "FatemiMaqala",
    "layer": [
      {
        "id": "default",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_Q",
                "text": "ض"
              },
              {
                "id": "K_W",
                "text": "ص"
              },
              {
                "id": "K_E",
                "text": "ث"
              },
              {
                "id": "K_R",
                "text": "ق"
              },
              {
                "id": "K_T",
                "text": "ف"
              },
              {
                "id": "K_Y",
                "text": "غ"
              },
              {
                "id": "K_U",
                "text": "ع"
              },
              {
                "id": "K_I",
                "text": "ه",
                "sk": [
                  {
                    "text": "ـہـ",
                    "id": "K_O",
                    "layer": "shift"
                  },
                  {
                    "text": "ـہ",
                    "id": "K_O",
                    "layer": "shift"
                  },
                  {
                    "text": "ھ",
                    "id": "K_I",
                    "layer": "shift"
                  },
                  {
                    "text": "ة",
                    "id": "K_M"
                  },
                  {
                    "text": "ۂ",
                    "id": "T_goalHamza"
                  }
                ]
              },
              {
                "id": "K_O",
                "text": "خ"
              },
              {
                "id": "K_P",
                "text": "ح"
              },
              {
                "id": "K_LBRKT",
                "text": "ج",
                "sk": [
                  {
                    "text": "چ",
                    "id": "K_LBRKT",
                    "layer": "shift"
                  },
                  {
                    "text": "چھے",
                    "id": "K_P",
                    "layer": "shift"
                  }
                ]
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_A",
                "text": "ش",
                "pad": "70"
              },
              {
                "id": "K_S",
                "text": "س"
              },
              {
                "id": "K_D",
                "text": "ي",
                "sk": [
                  {
                    "text": "ئ",
                    "id": "K_Z"
                  },
                  {
                    "text": "ى",
                    "id": "K_N"
                  },
                  {
                    "text": "ے",
                    "id": "K_D",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_F",
                "text": "ب"
              },
              {
                "id": "K_G",
                "text": "ل",
                "sk": [
                  {
                    "text": "لا",
                    "id": "T_Laa"
                  },
                  {
                    "text": "لأ",
                    "id": "T_LaaU"
                  },
                  {
                    "text": "لإ",
                    "id": "T_LaaD"
                  },
                  {
                    "text": "لآ",
                    "id": "T_LaaM"
                  },
                  {
                    "text": "لاٰ",
                    "id": "T_LaaK"
                  }
                ]
              },
              {
                "id": "K_H",
                "text": "ا",
                "sk": [
                  {
                    "text": "أ",
                    "id": "K_H",
                    "layer": "shift"
                  },
                  {
                    "text": "إ",
                    "id": "K_Y",
                    "layer": "shift"
                  },
                  {
                    "text": "آ",
                    "id": "K_N",
                    "layer": "shift"
                  },
                  {
                    "text": "اٰ",
                    "id": "K_G",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_J",
                "text": "ت"
              },
              {
                "id": "K_K",
                "text": "ن"
              },
              {
                "id": "K_L",
                "text": "م",
                "pad": ""
              },
              {
                "id": "K_COLON",
                "text": "ك",
                "width": "",
                "sk": [
                  {
                    "text": "گ",
                    "id": "K_COLON",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "T_new_2169",
                "text": "",
                "width": "10",
                "sp": "10"
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_SHIFT",
                "text": "*Shift*",
                "width": "150",
                "sp": "1",
                "nextlayer": "shift"
              },
              {
                "id": "K_BKQUOTE",
                "text": "ذ",
                "pad": ""
              },
              {
                "id": "K_SLASH",
                "text": "ظ"
              },
              {
                "id": "K_C",
                "text": "ؤ"
              },
              {
                "id": "K_V",
                "text": "ر",
                "sk": [
                  {
                    "text": "ڑ",
                    "id": "T_Rreh"
                  }
                ]
              },
              {
                "id": "K_PERIOD",
                "text": "ز"
              },
              {
                "id": "K_COMMA",
                "text": "و"
              },
              {
                "id": "K_QUOTE",
                "text": "ط",
                "nextlayer": "default"
              },
              {
                "id": "K_RBRKT",
                "text": "د",
                "sk": [
                  {
                    "text": "ڈ",
                    "id": "T_Ddeh"
                  }
                ]
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "width": "150",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_NUMLOCK",
                "text": "*123*",
                "width": "120",
                "sp": "1",
                "nextlayer": "numeric"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "100",
                "sp": "1"
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "425",
                "sp": "1"
              },
              {
                "id": "K_HELP",
                "text": "اعراب",
                "width": "120",
                "sk": [
                  {
                    "text": "زبر",
                    "id": "K_Q",
                    "layer": "shift"
                  },
                  {
                    "text": "زير",
                    "id": "K_A",
                    "layer": "shift"
                  },
                  {
                    "text": "پيش",
                    "id": "K_W",
                    "layer": "shift"
                  },
                  {
                    "text": "جزم",
                    "id": "K_X",
                    "layer": "shift"
                  },
                  {
                    "text": "~",
                    "id": "T_Maddah"
                  }
                ]
              },
              {
                "id": "K_PERIOD",
                "text": ".",
                "width": "100",
                "layer": "shift",
                "sk": [
                  {
                    "text": ".",
                    "id": "K_PERIOD",
                    "layer": "shift"
                  },
                  {
                    "text": "!",
                    "id": "K_1",
                    "layer": "shift"
                  },
                  {
                    "text": "؟",
                    "id": "K_SLASH",
                    "layer": "shift"
                  },
                  {
                    "text": "،",
                    "id": "K_K",
                    "layer": "shift"
                  },
                  {
                    "text": "؛",
                    "id": "T_Semi"
                  },
                  {
                    "text": "/",
                    "id": "K_COMMA",
                    "layer": "shift"
                  },
                  {
                    "text": "\\",
                    "id": "K_BKSLASH"
                  },
                  {
                    "text": "\"",
                    "id": "K_QUOTE",
                    "layer": "shift"
                  },
                  {
                    "text": "'",
                    "id": "T_SingQuote"
                  },
                  {
                    "text": "٬",
                    "id": "K_B",
                    "layer": "shift"
                  }
                ]
              },
              {
                "id": "K_X",
                "text": "ء"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      },
      {
        "id": "shift",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_Q",
                "text": "زبر"
              },
              {
                "id": "K_W",
                "text": "پيش"
              },
              {
                "id": "K_E",
                "text": "ا پيش"
              },
              {
                "id": "K_R",
                "text": "ـؕ"
              },
              {
                "id": "T_SAW",
                "text": "ـؐ",
                "layer": "default"
              },
              {
                "id": "T_AS",
                "text": "ـؑ",
                "layer": "default"
              },
              {
                "id": "T_SA",
                "text": "ـ",
                "layer": "default"
              },
              {
                "id": "K_I",
                "text": "ھ"
              },
              {
                "id": "K_U",
                "text": "ژ"
              },
              {
                "id": "K_P",
                "text": "چھے"
              },
              {
                "id": "K_LBRKT",
                "text": "چ"
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_A",
                "text": "زير",
                "pad": "30"
              },
              {
                "id": "T_KZabr",
                "text": "ك زبر",
                "layer": "default"
              },
              {
                "id": "K_D",
                "text": "ے"
              },
              {
                "id": "K_F",
                "text": "پ"
              },
              {
                "id": "T_TUS",
                "text": "ـ",
                "layer": "default"
              },
              {
                "id": "T_RA",
                "text": "ـؓ",
                "layer": "default"
              },
              {
                "id": "K_J",
                "text": "ـ"
              },
              {
                "id": "K_K",
                "text": "،"
              },
              {
                "id": "K_L",
                "text": "ں"
              },
              {
                "id": "K_COLON",
                "text": "گ"
              },
              {
                "id": "T_B",
                "text": "",
                "width": "60",
                "layer": "default",
                "sk": [
                  {
                    "text": "",
                    "id": "T_B",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BH",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BHS",
                    "layer": "default"
                  },
                  {
                    "text": "",
                    "id": "T_BHHS",
                    "layer": "default"
                  }
                ]
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_SHIFT",
                "text": "",
                "width": "150",
                "sp": "2",
                "nextlayer": "default"
              },
              {
                "id": "K_X",
                "text": "جزم"
              },
              {
                "id": "T_KZer",
                "text": "ك زير",
                "layer": "default"
              },
              {
                "id": "K_C",
                "text": "ـۚ"
              },
              {
                "id": "T_Rreh",
                "text": "ڑ",
                "layer": "default"
              },
              {
                "id": "T_QR",
                "text": "",
                "layer": "default"
              },
              {
                "id": "T_RH",
                "text": "ـؒ",
                "layer": "default"
              },
              {
                "id": "T_tteh",
                "text": "ٹ",
                "layer": "default"
              },
              {
                "id": "T_ddeh",
                "text": "ڈ",
                "layer": "default"
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "width": "150",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_NUMLOCK",
                "text": "*123*",
                "width": "150",
                "sp": "1",
                "nextlayer": "numeric"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "120",
                "sp": "1"
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "200",
                "sp": "0"
              },
              {
                "id": "K_N",
                "text": "ى",
                "layer": "default"
              },
              {
                "id": "K_1",
                "text": "!"
              },
              {
                "id": "K_SLASH",
                "text": "؟"
              },
              {
                "id": "K_QUOTE",
                "text": "\""
              },
              {
                "id": "K_8",
                "text": "۞"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      },
      {
        "id": "numeric",
        "row": [
          {
            "id": 1,
            "key": [
              {
                "id": "K_1",
                "text": "1",
                "sk": [
                  {
                    "text": "١",
                    "id": "T_Ara1"
                  },
                  {
                    "text": "૧",
                    "id": "T_Guj1"
                  }
                ]
              },
              {
                "id": "K_2",
                "text": "2",
                "sk": [
                  {
                    "text": "٢",
                    "id": "T_Ara2"
                  },
                  {
                    "text": "૨",
                    "id": "T_Guj2"
                  }
                ]
              },
              {
                "id": "K_3",
                "text": "3",
                "sk": [
                  {
                    "text": "٣",
                    "id": "T_Ara3"
                  },
                  {
                    "text": "૩",
                    "id": "T_Guj3"
                  }
                ]
              },
              {
                "id": "K_4",
                "text": "4",
                "sk": [
                  {
                    "text": "٤",
                    "id": "T_Ara4"
                  },
                  {
                    "text": "૪",
                    "id": "T_Guj4"
                  }
                ]
              },
              {
                "id": "K_5",
                "text": "5",
                "sk": [
                  {
                    "text": "٥",
                    "id": "T_Ara5"
                  },
                  {
                    "text": "૫",
                    "id": "T_Guj5"
                  }
                ]
              },
              {
                "id": "K_6",
                "text": "6",
                "sk": [
                  {
                    "text": "٦",
                    "id": "T_Ara6"
                  },
                  {
                    "text": "૬",
                    "id": "T_Guj6"
                  }
                ]
              },
              {
                "id": "K_7",
                "text": "7",
                "sk": [
                  {
                    "text": "٧",
                    "id": "T_Ara7"
                  },
                  {
                    "text": "૭",
                    "id": "T_Guj7"
                  }
                ]
              },
              {
                "id": "K_8",
                "text": "8",
                "sk": [
                  {
                    "text": "٨",
                    "id": "T_Ara8"
                  },
                  {
                    "text": "૮",
                    "id": "T_Guj8"
                  }
                ]
              },
              {
                "id": "k_9",
                "text": "9",
                "sk": [
                  {
                    "text": "٩",
                    "id": "T_Ara9"
                  },
                  {
                    "text": "૯",
                    "id": "T_Guj9"
                  }
                ]
              },
              {
                "id": "K_0",
                "text": "0",
                "sk": [
                  {
                    "text": "٠",
                    "id": "T_Ara0"
                  },
                  {
                    "text": "૰",
                    "id": "T_Guj0"
                  }
                ]
              }
            ]
          },
          {
            "id": 2,
            "key": [
              {
                "id": "K_4",
                "text": "$",
                "layer": "shift",
                "sk": [
                  {
                    "text": "₨",
                    "id": "T_Rupee"
                  },
                  {
                    "text": "¥",
                    "id": "T_Yen"
                  },
                  {
                    "text": "؋",
                    "id": "T_Afghani"
                  },
                  {
                    "text": "؈",
                    "id": "T_Ray"
                  },
                  {
                    "text": "૱",
                    "id": "T_GujRup"
                  }
                ]
              },
              {
                "id": "K_3",
                "text": "#",
                "layer": "shift"
              },
              {
                "id": "K_5",
                "text": "%",
                "layer": "shift",
                "sk": [
                  {
                    "text": "٪",
                    "id": "T_arabPercent"
                  }
                ]
              },
              {
                "id": "T_Caret",
                "text": "^"
              },
              {
                "id": "K_7",
                "text": "<",
                "layer": "shift"
              },
              {
                "id": "K_6",
                "text": ">",
                "layer": "shift"
              },
              {
                "id": "K_EQUAL",
                "text": "+",
                "layer": "shift",
                "sk": [
                  {
                    "text": "×",
                    "id": "T_mult"
                  }
                ]
              },
              {
                "id": "K_EQUAL",
                "text": "="
              },
              {
                "id": "T_Asterisk",
                "text": "*",
                "sk": [
                  {
                    "text": "٭",
                    "id": "T_fivepoint"
                  }
                ]
              },
              {
                "id": "K_HYPHEN",
                "text": "-",
                "sk": [
                  {
                    "text": "÷",
                    "id": "T_Divide"
                  },
                  {
                    "text": "_",
                    "id": "K_HYPHEN",
                    "layer": "shift"
                  }
                ]
              }
            ]
          },
          {
            "id": 3,
            "key": [
              {
                "id": "K_2",
                "text": "@",
                "layer": "shift"
              },
              {
                "id": "K_0",
                "text": "(",
                "layer": "shift"
              },
              {
                "id": "K_9",
                "text": ")",
                "layer": "shift"
              },
              {
                "id": "T_Misra",
                "text": "؏"
              },
              {
                "id": "T_Takhallus",
                "text": "ؔ"
              },
              {
                "id": "T_Safha",
                "text": "؃"
              },
              {
                "id": "T_Footnote",
                "text": "؂",
                "sk": [
                  {
                    "text": "؎",
                    "id": "T_poetry"
                  }
                ]
              },
              {
                "id": "T_Sanah",
                "text": "؁",
                "sk": [
                  {
                    "text": "؄",
                    "id": "T_Samvat"
                  }
                ]
              },
              {
                "id": "T_Number",
                "text": "؀",
                "sk": [
                  {
                    "text": "۝",
                    "id": "T_Ayah"
                  },
                  {
                    "text": "۩",
                    "id": "T_Sajda"
                  }
                ]
              },
              {
                "id": "K_BKSP",
                "text": "*BkSp*",
                "sp": "1"
              }
            ]
          },
          {
            "id": 4,
            "key": [
              {
                "id": "K_LOWER",
                "text": "*abc*",
                "width": "150",
                "sp": "1",
                "nextlayer": "default"
              },
              {
                "id": "K_S",
                "text": "mod",
                "layer": "shift"
              },
              {
                "id": "K_LOPT",
                "text": "*Menu*",
                "width": "120",
                "sp": "1"
              },
              {
                "id": "K_SPACE",
                "text": "",
                "width": "500",
                "sp": "0"
              },
              {
                "id": "K_ENTER",
                "text": "*Enter*",
                "width": "150",
                "sp": "1"
              }
            ]
          }
        ]
      }
    ]
  }
}
;
  this.s_modkeys1="...........";
  this.s_modvalues1="٠١٢٣٤٥٦٧٨٩؍";
  this.s_modkeys2="...........";
  this.s_modvalues2="؀؂؆₨*^٭﴿﴾÷×";
  this.s_modkeys3="...........";
  this.s_modvalues3="ؐ؃؎؏ؑۂؔؒۚ۩|";
  this.s_modkeys4="......";
  this.s_modvalues4="؄؁ۓٮڡ۝";
  this.s_modkeys5=".....";
  this.s_modvalues5="؛‌‍{}";
  this.s_doubleKeys=".....";
  this.s_doubleChars="سضظطح";
  this.s_doubleOut="ےٹہںچ";
  this.s_iraabKey="....";
  this.s_iraabs="َُِْ";
  this.s_iraabStrength="ّٰٖٗ";
  this.KVER="13.0.108.0";
  this.gs=function(t,e) {
    return this.g_main(t,e);
  };
  this.g_main=function(t,e) {
    var k=KeymanWeb,r=0,m=0;
    if(k.KKM(e, 0x4000, 0x100)) {
      if(1){
        r=m=1;   // Line 81
        k.KO(0,t,"ؐ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x101)) {
      if(1){
        r=m=1;   // Line 82
        k.KO(0,t,"^صع");
      }
    }
    else if(k.KKM(e, 0x4000, 0x102)) {
      if(1){
        r=m=1;   // Line 83
        k.KO(0,t,"ؑ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x103)) {
      if(1){
        r=m=1;   // Line 84
        k.KO(0,t,"ؓ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x104)) {
      if(1){
        r=m=1;   // Line 85
        k.KO(0,t,"^طع");
      }
    }
    else if(k.KKM(e, 0x4000, 0x105)) {
      if(1){
        r=m=1;   // Line 86
        k.KO(0,t,"^قس");
      }
    }
    else if(k.KKM(e, 0x4000, 0x106)) {
      if(1){
        r=m=1;   // Line 87
        k.KO(0,t,"ؒ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x107)) {
      if(1){
        r=m=1;   // Line 89
        k.KO(0,t,"!ب!");
      }
    }
    else if(k.KKM(e, 0x4000, 0x108)) {
      if(1){
        r=m=1;   // Line 90
        k.KO(0,t,"!بص!");
      }
    }
    else if(k.KKM(e, 0x4000, 0x109)) {
      if(1){
        r=m=1;   // Line 91
        k.KO(0,t,"!بهص!");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10A)) {
      if(1){
        r=m=1;   // Line 92
        k.KO(0,t,"!بههص!");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10B)) {
      if(1){
        r=m=1;   // Line 94
        k.KO(0,t,"ٰ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10C)) {
      if(1){
        r=m=1;   // Line 95
        k.KO(0,t,"ٖ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10D)) {
      if(1){
        r=m=1;   // Line 96
        k.KO(0,t,"ٓ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10E)) {
      if(1){
        r=m=1;   // Line 98
        k.KO(0,t,"؛");
      }
    }
    else if(k.KKM(e, 0x4000, 0x10F)) {
      if(1){
        r=m=1;   // Line 99
        k.KO(0,t,"'");
      }
    }
    else if(k.KKM(e, 0x4000, 0x110)) {
      if(1){
        r=m=1;   // Line 101
        k.KO(0,t,"ۂ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x111)) {
      if(1){
        r=m=1;   // Line 103
        k.KO(0,t,"لا");
      }
    }
    else if(k.KKM(e, 0x4000, 0x112)) {
      if(1){
        r=m=1;   // Line 104
        k.KO(0,t,"لأ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x113)) {
      if(1){
        r=m=1;   // Line 105
        k.KO(0,t,"لإ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x114)) {
      if(1){
        r=m=1;   // Line 106
        k.KO(0,t,"لاٰ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x115)) {
      if(1){
        r=m=1;   // Line 107
        k.KO(0,t,"لآ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x116)) {
      if(1){
        r=m=1;   // Line 109
        k.KO(0,t,"ڑ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x117)) {
      if(1){
        r=m=1;   // Line 110
        k.KO(0,t,"ڈ‎");
      }
    }
    else if(k.KKM(e, 0x4000, 0x118)) {
      if(1){
        r=m=1;   // Line 111
        k.KO(0,t,"ٹ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x119)) {
      if(1){
        r=m=1;   // Line 113
        k.KO(0,t,"٠");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11A)) {
      if(1){
        r=m=1;   // Line 114
        k.KO(0,t,"١");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11B)) {
      if(1){
        r=m=1;   // Line 115
        k.KO(0,t,"٢");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11C)) {
      if(1){
        r=m=1;   // Line 116
        k.KO(0,t,"٣");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11D)) {
      if(1){
        r=m=1;   // Line 117
        k.KO(0,t,"٤");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11E)) {
      if(1){
        r=m=1;   // Line 118
        k.KO(0,t,"٥");
      }
    }
    else if(k.KKM(e, 0x4000, 0x11F)) {
      if(1){
        r=m=1;   // Line 119
        k.KO(0,t,"٦");
      }
    }
    else if(k.KKM(e, 0x4000, 0x120)) {
      if(1){
        r=m=1;   // Line 120
        k.KO(0,t,"٧");
      }
    }
    else if(k.KKM(e, 0x4000, 0x121)) {
      if(1){
        r=m=1;   // Line 121
        k.KO(0,t,"٨");
      }
    }
    else if(k.KKM(e, 0x4000, 0x122)) {
      if(1){
        r=m=1;   // Line 122
        k.KO(0,t,"٩");
      }
    }
    else if(k.KKM(e, 0x4000, 0x123)) {
      if(1){
        r=m=1;   // Line 124
        k.KO(0,t,"૦");
      }
    }
    else if(k.KKM(e, 0x4000, 0x124)) {
      if(1){
        r=m=1;   // Line 125
        k.KO(0,t,"૧");
      }
    }
    else if(k.KKM(e, 0x4000, 0x125)) {
      if(1){
        r=m=1;   // Line 126
        k.KO(0,t,"૨");
      }
    }
    else if(k.KKM(e, 0x4000, 0x126)) {
      if(1){
        r=m=1;   // Line 127
        k.KO(0,t,"૩");
      }
    }
    else if(k.KKM(e, 0x4000, 0x127)) {
      if(1){
        r=m=1;   // Line 128
        k.KO(0,t,"૪");
      }
    }
    else if(k.KKM(e, 0x4000, 0x128)) {
      if(1){
        r=m=1;   // Line 129
        k.KO(0,t,"૫");
      }
    }
    else if(k.KKM(e, 0x4000, 0x129)) {
      if(1){
        r=m=1;   // Line 130
        k.KO(0,t,"૬");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12A)) {
      if(1){
        r=m=1;   // Line 131
        k.KO(0,t,"૭");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12B)) {
      if(1){
        r=m=1;   // Line 132
        k.KO(0,t,"૮");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12C)) {
      if(1){
        r=m=1;   // Line 133
        k.KO(0,t,"૯");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12D)) {
      if(1){
        r=m=1;   // Line 135
        k.KO(0,t,"؋");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12E)) {
      if(1){
        r=m=1;   // Line 136
        k.KO(0,t,"¥");
      }
    }
    else if(k.KKM(e, 0x4000, 0x12F)) {
      if(1){
        r=m=1;   // Line 137
        k.KO(0,t,"؈");
      }
    }
    else if(k.KKM(e, 0x4000, 0x130)) {
      if(1){
        r=m=1;   // Line 138
        k.KO(0,t,"૱");
      }
    }
    else if(k.KKM(e, 0x4000, 0x131)) {
      if(1){
        r=m=1;   // Line 139
        k.KO(0,t,"₨");
      }
    }
    else if(k.KKM(e, 0x4000, 0x132)) {
      if(1){
        r=m=1;   // Line 141
        k.KO(0,t,"×");
      }
    }
    else if(k.KKM(e, 0x4000, 0x133)) {
      if(1){
        r=m=1;   // Line 142
        k.KO(0,t,"÷");
      }
    }
    else if(k.KKM(e, 0x4000, 0x134)) {
      if(1){
        r=m=1;   // Line 143
        k.KO(0,t,"*");
      }
    }
    else if(k.KKM(e, 0x4000, 0x135)) {
      if(1){
        r=m=1;   // Line 144
        k.KO(0,t,"٭");
      }
    }
    else if(k.KKM(e, 0x4000, 0x136)) {
      if(1){
        r=m=1;   // Line 145
        k.KO(0,t,"‸");
      }
    }
    else if(k.KKM(e, 0x4000, 0x137)) {
      if(1){
        r=m=1;   // Line 146
        k.KO(0,t,"‍");
      }
    }
    else if(k.KKM(e, 0x4000, 0x138)) {
      if(1){
        r=m=1;   // Line 147
        k.KO(0,t,"‌");
      }
    }
    else if(k.KKM(e, 0x4000, 0x139)) {
      if(1){
        r=m=1;   // Line 149
        k.KO(0,t,"؁");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13A)) {
      if(1){
        r=m=1;   // Line 150
        k.KO(0,t,"؄");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13B)) {
      if(1){
        r=m=1;   // Line 151
        k.KO(0,t,"؂");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13C)) {
      if(1){
        r=m=1;   // Line 152
        k.KO(0,t,"؃");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13D)) {
      if(1){
        r=m=1;   // Line 153
        k.KO(0,t,"ؒ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13E)) {
      if(1){
        r=m=1;   // Line 154
        k.KO(0,t,"؀");
      }
    }
    else if(k.KKM(e, 0x4000, 0x13F)) {
      if(1){
        r=m=1;   // Line 155
        k.KO(0,t,"ؔ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x140)) {
      if(1){
        r=m=1;   // Line 156
        k.KO(0,t,"؏");
      }
    }
    else if(k.KKM(e, 0x4000, 0x141)) {
      if(1){
        r=m=1;   // Line 157
        k.KO(0,t,"ۡ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x142)) {
      if(1){
        r=m=1;   // Line 158
        k.KO(0,t,"۩");
      }
    }
    else if(k.KKM(e, 0x4000, 0x143)) {
      if(1){
        r=m=1;   // Line 159
        k.KO(0,t,"٪");
      }
    }
    else if(k.KKM(e, 0x4010, 0x31)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"؂");
      }
      else if(1){
        r=m=1;   // Line 188
        k.KO(0,t,"!");
      }
    }
    else if(k.KKM(e, 0x4010, 0xDE)) {
      if(1){
        r=m=1;   // Line 202
        k.KO(0,t,"\"");
      }
    }
    else if(k.KKM(e, 0x4010, 0x33)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"₨");
      }
      else if(1){
        r=m=1;   // Line 186
        k.KO(0,t,"#");
      }
    }
    else if(k.KKM(e, 0x4010, 0x34)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"*");
      }
      else if(1){
        r=m=1;   // Line 185
        k.KO(0,t,"$");
      }
    }
    else if(k.KKM(e, 0x4010, 0x35)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"^");
      }
      else if(1){
        r=m=1;   // Line 184
        k.KO(0,t,"%");
      }
    }
    else if(k.KKM(e, 0x4010, 0x37)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"﴿");
      }
      else if(1){
        r=m=1;   // Line 182
        k.KO(0,t,"<");
      }
    }
    else if(k.KKM(e, 0x4000, 0xDE)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 46
        k.KO(0,t,"^طع");
      }
      else if(k.KCM(1,t,"ط",1)){
        r=m=1;   // Line 60
        k.KO(1,t,"ں");
      }
      else if(1){
        r=m=1;   // Line 239
        k.KO(0,t,"ط");
      }
    }
    else if(k.KKM(e, 0x4010, 0x39)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"÷");
      }
      else if(1){
        r=m=1;   // Line 180
        k.KO(0,t,")");
      }
    }
    else if(k.KKM(e, 0x4010, 0x30)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"؀");
      }
      else if(1){
        r=m=1;   // Line 179
        k.KO(0,t,"(");
      }
    }
    else if(k.KKM(e, 0x4010, 0x38)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"﴾");
      }
      else if(1){
        r=m=1;   // Line 181
        k.KO(0,t,"۞");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBB)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"×");
      }
      else if(1){
        r=m=1;   // Line 177
        k.KO(0,t,"+");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBC)) {
      if(1){
        r=m=1;   // Line 230
        k.KO(0,t,"و");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBD)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"؍");
      }
      else if(1){
        r=m=1;   // Line 164
        k.KO(0,t,"-");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBE)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 42
        k.KO(0,t,"‌");
      }
      else if(1){
        r=m=1;   // Line 229
        k.KO(0,t,"ز");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBF)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 42
        k.KO(0,t,"‍");
      }
      else if(k.KCM(1,t,"ظ",1)){
        r=m=1;   // Line 61
        k.KO(1,t,"ہ");
      }
      else if(1){
        r=m=1;   // Line 228
        k.KO(0,t,"ظ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x30)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٠");
      }
      else if(1){
        r=m=1;   // Line 165
        k.KO(0,t,"0");
      }
    }
    else if(k.KKM(e, 0x4000, 0x31)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"١");
      }
      else if(1){
        r=m=1;   // Line 174
        k.KO(0,t,"1");
      }
    }
    else if(k.KKM(e, 0x4000, 0x32)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٢");
      }
      else if(1){
        r=m=1;   // Line 173
        k.KO(0,t,"2");
      }
    }
    else if(k.KKM(e, 0x4000, 0x33)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٣");
      }
      else if(1){
        r=m=1;   // Line 172
        k.KO(0,t,"3");
      }
    }
    else if(k.KKM(e, 0x4000, 0x34)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٤");
      }
      else if(1){
        r=m=1;   // Line 171
        k.KO(0,t,"4");
      }
    }
    else if(k.KKM(e, 0x4000, 0x35)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٥");
      }
      else if(1){
        r=m=1;   // Line 170
        k.KO(0,t,"5");
      }
    }
    else if(k.KKM(e, 0x4000, 0x36)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٦");
      }
      else if(1){
        r=m=1;   // Line 169
        k.KO(0,t,"6");
      }
    }
    else if(k.KKM(e, 0x4000, 0x37)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٧");
      }
      else if(1){
        r=m=1;   // Line 168
        k.KO(0,t,"7");
      }
    }
    else if(k.KKM(e, 0x4000, 0x38)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٨");
      }
      else if(1){
        r=m=1;   // Line 167
        k.KO(0,t,"8");
      }
    }
    else if(k.KKM(e, 0x4000, 0x39)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 38
        k.KO(0,t,"٩");
      }
      else if(1){
        r=m=1;   // Line 166
        k.KO(0,t,"9");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBA)) {
      if(1){
        r=m=1;   // Line 203
        k.KO(0,t,"گ");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBA)) {
      if(k.KCM(1,t,"ك",1)){
        r=m=1;   // Line 64
        k.KO(1,t,"گ");
      }
      else if(1){
        r=m=1;   // Line 240
        k.KO(0,t,"ك");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBC)) {
      if(1){
        r=m=1;   // Line 193
        k.KO(0,t,"/");
      }
    }
    else if(k.KKM(e, 0x4000, 0xBB)) {
      if(1){
        r=m=1;   // Line 163
        k.KO(0,t,"=");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBE)) {
      if(k.KCM(1,t,".",1)){
        r=m=1;   // Line 74
        k.KO(1,t,":");
      }
      else if(k.KCM(1,t,":",1)){
        r=m=1;   // Line 75
        k.KO(1,t,"…");
      }
      else if(1){
        r=m=1;   // Line 192
        k.KO(0,t,".");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBF)) {
      if(1){
        r=m=1;   // Line 191
        k.KO(0,t,"؟");
      }
    }
    else if(k.KKM(e, 0x4010, 0x32)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"؆");
      }
      else if(1){
        r=m=1;   // Line 187
        k.KO(0,t,"@");
      }
    }
      if(m) {}
    else if(k.KKM(e, 0x4010, 0x41)) {
      if(k.KCM(1,t,"ِ",1)){
        r=m=1;   // Line 68
        k.KO(1,t,"ٍ");
      }
      else if(1){
        r=m=1;   // Line 212
        k.KO(0,t,"ِ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x42)) {
      if(k.KCM(1,t,"٬",1)){
        r=m=1;   // Line 76
        k.KO(1,t,"٫");
      }
      else if(1){
        r=m=1;   // Line 196
        k.KO(0,t,"٬");
      }
    }
    else if(k.KKM(e, 0x4010, 0x43)) {
      if(1){
        r=m=1;   // Line 198
        k.KO(0,t,"ۚ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x44)) {
      if(1){
        r=m=1;   // Line 210
        k.KO(0,t,"ے");
      }
    }
    else if(k.KKM(e, 0x4010, 0x45)) {
      if(1){
        r=m=1;   // Line 224
        k.KO(0,t,"ٗ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x46)) {
      if(1){
        r=m=1;   // Line 209
        k.KO(0,t,"پ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x47)) {
      if(1){
        r=m=1;   // Line 208
        k.KO(0,t,"اٰ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x48)) {
      if(1){
        r=m=1;   // Line 207
        k.KO(0,t,"أ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x49)) {
      if(1){
        r=m=1;   // Line 219
        k.KO(0,t,"ھ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4A)) {
      if(1){
        r=m=1;   // Line 206
        k.KO(0,t,"ـ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4B)) {
      if(k.KCM(1,t,"،",1)){
        r=m=1;   // Line 73
        k.KO(1,t,"؛");
      }
      else if(1){
        r=m=1;   // Line 205
        k.KO(0,t,"،");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4C)) {
      if(1){
        r=m=1;   // Line 204
        k.KO(0,t,"ں");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4D)) {
      if(1){
        r=m=1;   // Line 194
        k.KO(0,t,"ۃ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4E)) {
      if(1){
        r=m=1;   // Line 195
        k.KO(0,t,"آ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x4F)) {
      if(1){
        r=m=1;   // Line 218
        k.KO(0,t,"ہ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x50)) {
      if(1){
        r=m=1;   // Line 217
        k.KO(0,t,"چھے");
      }
    }
    else if(k.KKM(e, 0x4010, 0x51)) {
      if(k.KCM(1,t,"َ",1)){
        r=m=1;   // Line 67
        k.KO(1,t,"ً");
      }
      else if(1){
        r=m=1;   // Line 226
        k.KO(0,t,"َ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x52)) {
      if(k.KCM(1,t,"ر",1)){
        r=m=1;   // Line 53
        k.KO(1,t,"ڑ");
      }
      else if(k.KCM(1,t,"ت",1)){
        r=m=1;   // Line 54
        k.KO(1,t,"ٹ");
      }
      else if(k.KCM(1,t,"د",1)){
        r=m=1;   // Line 55
        k.KO(1,t,"ڈ");
      }
      else if(1){
        r=m=1;   // Line 223
        k.KO(0,t,"ؕ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x53)) {
      if(1){
        r=m=1;   // Line 35
        k.KDO(0,t,0);
      }
    }
    else if(k.KKM(e, 0x4010, 0x54)) {
      if(1){
        r=m=1;   // Line 222
        k.KO(0,t,"ڤ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x55)) {
      if(1){
        r=m=1;   // Line 220
        k.KO(0,t,"ژ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x56)) {
      if(1){
        r=m=1;   // Line 197
        k.KO(0,t,"ۨ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x57)) {
      if(k.KCM(1,t,"ُ",1)){
        r=m=1;   // Line 69
        k.KO(1,t,"ٌ");
      }
      else if(1){
        r=m=1;   // Line 225
        k.KO(0,t,"ُ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x58)) {
      if(k.KA(0,k.KC(1,1,t),this.s_iraabs)){
        r=m=1;   // Line 70
        k.KIO(1,this.s_iraabStrength,1,t);
      }
      else if(k.KCM(1,t,"ٰ",1)){
        r=m=1;   // Line 71
        k.KO(1,t,"ٓ");
      }
      else if(1){
        r=m=1;   // Line 199
        k.KO(0,t,"ْ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x59)) {
      if(1){
        r=m=1;   // Line 221
        k.KO(0,t,"إ");
      }
    }
    else if(k.KKM(e, 0x4010, 0x5A)) {
      if(1){
        r=m=1;   // Line 200
        k.KO(0,t,"ٓ");
      }
    }
    else if(k.KKM(e, 0x4000, 0xDB)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ۚ");
      }
      else if(1){
        r=m=1;   // Line 253
        k.KO(0,t,"ج");
      }
    }
    else if(k.KKM(e, 0x4000, 0xDC)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"|");
      }
      else if(1){
        r=m=1;   // Line 251
        k.KO(0,t,"\\");
      }
    }
    else if(k.KKM(e, 0x4000, 0xDD)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"۩");
      }
      else if(1){
        r=m=1;   // Line 252
        k.KO(0,t,"د");
      }
    }
    else if(k.KKM(e, 0x4010, 0x36)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 39
        k.KO(0,t,"٭");
      }
      else if(1){
        r=m=1;   // Line 183
        k.KO(0,t,">");
      }
    }
    else if(k.KKM(e, 0x4010, 0xBD)) {
      if(1){
        r=m=1;   // Line 178
        k.KO(0,t,"_");
      }
    }
    else if(k.KKM(e, 0x4000, 0xC0)) {
      if(1){
        r=m=1;   // Line 162
        k.KO(0,t,"ذ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x41)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"؄");
      }
      else if(1){
        r=m=1;   // Line 249
        k.KO(0,t,"ش");
      }
    }
    else if(k.KKM(e, 0x4000, 0x42)) {
      if(1){
        r=m=1;   // Line 233
        k.KO(0,t,"ال");
      }
    }
    else if(k.KKM(e, 0x4000, 0x43)) {
      if(1){
        r=m=1;   // Line 235
        k.KO(0,t,"ؤ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x44)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"ۓ");
      }
      else if(1){
        r=m=1;   // Line 247
        k.KO(0,t,"ي");
      }
    }
    else if(k.KKM(e, 0x4000, 0x45)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"؃");
      }
      else if(k.KCM(1,t,"ث",1)){
        r=m=1;   // Line 63
        k.KO(1,t,"پ");
      }
      else if(1){
        r=m=1;   // Line 261
        k.KO(0,t,"ث");
      }
    }
    else if(k.KKM(e, 0x4000, 0x46)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"ٮ");
      }
      else if(1){
        r=m=1;   // Line 246
        k.KO(0,t,"ب");
      }
    }
    else if(k.KKM(e, 0x4000, 0x47)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"ڡ");
      }
      else if(1){
        r=m=1;   // Line 245
        k.KO(0,t,"ل");
      }
    }
    else if(k.KKM(e, 0x4000, 0x48)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"۝");
      }
      else if(1){
        r=m=1;   // Line 244
        k.KO(0,t,"ا");
      }
    }
    else if(k.KKM(e, 0x4000, 0x49)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ۂ");
      }
      else if(1){
        r=m=1;   // Line 256
        k.KO(0,t,"ه");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4A)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 47
        k.KO(0,t,"!ب!");
      }
      else if(1){
        r=m=1;   // Line 243
        k.KO(0,t,"ت");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4B)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 48
        k.KO(0,t,"!بص!");
      }
      else if(1){
        r=m=1;   // Line 242
        k.KO(0,t,"ن");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4C)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 49
        k.KO(0,t,"!بهص!");
      }
      else if(1){
        r=m=1;   // Line 241
        k.KO(0,t,"م");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4D)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 50
        k.KO(0,t,"!بههص!");
      }
      else if(1){
        r=m=1;   // Line 231
        k.KO(0,t,"ة");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4E)) {
      if(1){
        r=m=1;   // Line 232
        k.KO(0,t,"ى");
      }
    }
    else if(k.KKM(e, 0x4000, 0x4F)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ؔ");
      }
      else if(1){
        r=m=1;   // Line 255
        k.KO(0,t,"خ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x50)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ؒ");
      }
      else if(k.KCM(1,t,"ح",1)){
        r=m=1;   // Line 62
        k.KO(1,t,"چ");
      }
      else if(1){
        r=m=1;   // Line 254
        k.KO(0,t,"ح");
      }
    }
    else if(k.KKM(e, 0x4000, 0x51)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 44
        k.KO(0,t,"^صع");
      }
      else if(k.KCM(1,t,"ض",1)){
        r=m=1;   // Line 59
        k.KO(1,t,"ٹ");
      }
      else if(1){
        r=m=1;   // Line 263
        k.KO(0,t,"ض");
      }
    }
    else if(k.KKM(e, 0x4000, 0x52)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 45
        k.KO(0,t,"^قس");
      }
      else if(1){
        r=m=1;   // Line 260
        k.KO(0,t,"ق");
      }
    }
    else if(k.KKM(e, 0x4000, 0x53)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 41
        k.KO(0,t,"؁");
      }
      else if(k.KCM(1,t,"س",1)){
        r=m=1;   // Line 58
        k.KO(1,t,"ے");
      }
      else if(1){
        r=m=1;   // Line 248
        k.KO(0,t,"س");
      }
    }
    else if(k.KKM(e, 0x4000, 0x54)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"؎");
      }
      else if(1){
        r=m=1;   // Line 259
        k.KO(0,t,"ف");
      }
    }
    else if(k.KKM(e, 0x4000, 0x55)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ؑ");
      }
      else if(1){
        r=m=1;   // Line 257
        k.KO(0,t,"ع");
      }
    }
    else if(k.KKM(e, 0x4000, 0x56)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 42
        k.KO(0,t,"؛");
      }
      else if(1){
        r=m=1;   // Line 234
        k.KO(0,t,"ر");
      }
    }
    else if(k.KKM(e, 0x4000, 0x57)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"ؐ");
      }
      else if(1){
        r=m=1;   // Line 262
        k.KO(0,t,"ص");
      }
    }
    else if(k.KKM(e, 0x4000, 0x58)) {
      if(k.KCM(1,t,"ء",1)){
        r=m=1;   // Line 66
        k.KO(1,t,"ٰ");
      }
      else if(k.KCM(1,t,"ى",1)){
        r=m=1;   // Line 77
        k.KO(1,t,"ئ");
      }
      else if(1){
        r=m=1;   // Line 236
        k.KO(0,t,"ء");
      }
    }
    else if(k.KKM(e, 0x4000, 0x59)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 40
        k.KO(0,t,"؏");
      }
      else if(1){
        r=m=1;   // Line 258
        k.KO(0,t,"غ");
      }
    }
    else if(k.KKM(e, 0x4000, 0x5A)) {
      if(k.KCM(1,t,"ئ",1)){
        r=m=1;   // Line 65
        k.KO(1,t,"ٖ");
      }
      else if(1){
        r=m=1;   // Line 237
        k.KO(0,t,"ئ");
      }
    }
    else if(k.KKM(e, 0x4010, 0xDB)) {
      if(1){
        r=m=1;   // Line 216
        k.KO(0,t,"چ");
      }
    }
    else if(k.KKM(e, 0x4010, 0xDC)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 42
        k.KO(0,t,"{");
      }
      else if(1){
        r=m=1;   // Line 214
        k.KO(0,t,"[");
      }
    }
    else if(k.KKM(e, 0x4010, 0xDD)) {
      if(k.KDM(0,t,0)){
        r=m=1;   // Line 42
        k.KO(0,t,"}");
      }
      else if(1){
        r=m=1;   // Line 215
        k.KO(0,t,"]");
      }
    }
    else if(k.KKM(e, 0x4010, 0xC0)) {
      if(1){
        r=m=1;   // Line 176
        k.KO(0,t,"ّ");
      }
    }
    return r;
  };
}
