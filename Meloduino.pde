/*
 * ----------------------------------------------------------------------------
 *
 * ~  Meloduino, the melody maker with bending sound  ~
 *    ver. 1
 * 
 * ----------------------------------------------------------------------------
 *
 * by Naokazu Terada, Karappo 
 * http://karappo.net/
 * 
 * < Help >
 * http://labs.karappo.net/
 *
 * < Changelog >
 * 8  Oct 2009 : ver.1     release
 * 12 Oct 2009 : ver.1.1   bug fix in bending
 * 
 * ----------------------------------------------------------------------------
 */

// PIN SETTING
#define SPEAKER_PIN 13
#define SW_PIN_1    4
#define SW_PIN_2    5
#define SW_PIN_3    6
#define SW_PIN_4    7

// SCORE CODES
#define SINGLE_NOTE_SILENCE   ' '
#define NOTE_DURATION         '-'
#define NOTE_BEND_DUR         '~'
#define OCTAVE_UP             '>'
#define OCTAVE_DOWN           '<'
#define LONG_SILENCE          '.'
#define ACCIDENTALS_PREFIX    '('
#define ACCIDENTALS_SUFFIX    ')'
#define GLOBAL_SETTING_PREFIX '['
#define GLOBAL_SETTING_SUFFIX ']'
#define IGNORE_NOTE           ','

#define BendStepsPerNote 10 // steps between Note and Note when bending score  
#define SILENCE_TIME 1000   // time of silence in score (milliseconds) *Change if you like
#define DEFAULT_MSpN 50     // default time per note (milliseconds)
int  globalOctave;          // maintain the global octave

/*
 * period = 1 / toneFrequency * 1000000
 *
 * note 	frequency 	period
 * A 	        493 Hz 	        2028
 * B 	        440 Hz 	        2273 
 * G 	        392 Hz 	        2551 	
 * F 	        349 Hz 	        2865 	
 * E 	        329 Hz 	        3040 	
 * D 	        294 Hz 	        3401 	
 * C 	        261 Hz 	        3831 	
 */

int  tonesAmount = 7;
char names[] = { 'C',  'D',  'E',  'F',  'G',  'A',  'B' };
int  tones[] = { 3831, 3401, 3040, 2865, 2551, 2273, 2028 };

// ----------------------------------------------------------------------------
// FUNCTIONS

// count chars
int count( char targetscore[], int startIndex, char targetChar)
{
  int num = 0;
  while(targetscore[startIndex + num] == targetChar) num++;
  return num;
}

unsigned long getTone(char targetScore[], int noteIndex) 
{
  char note = targetScore[noteIndex];
   
  // Check Accidentals
  int localOctave = 0;
  if( targetScore[noteIndex+1] == ACCIDENTALS_PREFIX )
  {
    int n = noteIndex+2;
    while( targetScore[n] != ACCIDENTALS_SUFFIX )
    {
      if( targetScore[n] == OCTAVE_UP ) localOctave++;
      else if( targetScore[n] == OCTAVE_DOWN ) localOctave--;
      n++;
    }
  }
  
  for (int i = 0; i < tonesAmount; i++) 
  {
    if (names[i] == note) 
    {
      localOctave = getValidOctave( globalOctave + localOctave );
      unsigned long tone = (unsigned long) tones[i] * pow(2, -localOctave);
//      Serial.println("( getTone )");
//      Serial.println(note);
//      Serial.println(localOctave);
//      Serial.println(tone);
//      Serial.println("___________");
      return tone;
    }
  }
}

// make pulse sound
void playTone(unsigned long tone, int duration) 
{
//  Serial.println("[[ playTone ]]");
//  Serial.println(tone);
//  Serial.println(duration);
//  Serial.println("___________");
  for (unsigned long i = 0; i < duration * 1000L; i += tone * 2)
  {
    digitalWrite(SPEAKER_PIN, HIGH);
    delayMicroseconds(tone);
    digitalWrite(SPEAKER_PIN, LOW);
    delayMicroseconds(tone);
  }
}

void playBendToneToTone(  unsigned long startTone, unsigned long endTone, 
                          int durationPerscore, int scoreNumWhileBending  )
{
  
  long toneDiffPerStep = (((long)endTone - (long)startTone)/BendStepsPerNote)/scoreNumWhileBending;
  int durationOfDevidedTones = durationPerscore/BendStepsPerNote;
//  Serial.println("[[ playBendToneToTone ]]");
//  Serial.println(startTone);
//  Serial.println(endTone);
//  Serial.println(durationPerscore);
//  Serial.println(scoreNumWhileBending);
//  Serial.println(toneDiffPerStep);
//  Serial.println(durationOfDevidedTones);
//  Serial.println("___________");
  for (long i = 0; i < BendStepsPerNote*scoreNumWhileBending; i++)
  {
    // < step >
    unsigned long currentTone = startTone + toneDiffPerStep*i;
    
    if( currentTone < 0 ) break;
    
    if( ( endTone < startTone ) && ( currentTone < endTone ) ) currentTone = endTone;
    if( ( startTone < endTone ) && ( endTone < currentTone ) ) currentTone = endTone;
    
    playTone(currentTone, durationOfDevidedTones);
    
    if( currentTone == endTone ) break;
  }
}

void playScore( char score[], int MSpN = DEFAULT_MSpN )
{
  // init octave setting
  globalOctave = 0;
  
  for (int i = 0; ; i++)
  {
    if (score[i] == '\0') 
    {
      // < end of score >
      break;
    }
    else if(score[i] == IGNORE_NOTE)
    {
      // < ignore score >
      // do nothing
    }
    else if (score[i] == GLOBAL_SETTING_PREFIX) 
    {
      // < global octave setting >
      int _octave = 0;
      while( score[i+1] != GLOBAL_SETTING_SUFFIX )
      {
        if( score[i+1] == OCTAVE_UP ) _octave++;
        else if( score[i+1] == OCTAVE_DOWN ) _octave--;
        i++;
      }
      globalOctave = getValidOctave( globalOctave + _octave );
    }
    else if (score[i] == LONG_SILENCE) 
    {
      // < long silence >
//      Ser/ial.println("... long silence ...");
      delay(SILENCE_TIME);
    }
    else if (score[i] == SINGLE_NOTE_SILENCE) 
    {
      // < single note silence >
      delay(MSpN);
    }
    else if((score[i] == 'C')||
            (score[i] == 'D')||
            (score[i] == 'E')||
            (score[i] == 'F')||
            (score[i] == 'G')||
            (score[i] == 'A')||
            (score[i] == 'B'))
    {
      unsigned long startNote = getTone(score, i);
      
      // move index forward ...
      if(score[i+1] == ACCIDENTALS_PREFIX) while( score[i] != ACCIDENTALS_SUFFIX ) i++;
      
      if(score[i+1] == NOTE_DURATION)
      {
        // < long note >
        int noteDurationNum = count(score, i+1, NOTE_DURATION);
        playTone(startNote, MSpN*noteDurationNum);
        i += noteDurationNum;
      }
      else if(score[i+1] == NOTE_BEND_DUR)
      {
        // < bend note >
        int noteDurationNum = count(score, i+1, NOTE_BEND_DUR);
        i += noteDurationNum+1;
        
        unsigned long endNote = getTone(score, i);
        playBendToneToTone(startNote, endNote, MSpN, noteDurationNum);
        
        // move index forward ...
        if(score[i+1] == ACCIDENTALS_PREFIX) while( score[i] != ACCIDENTALS_SUFFIX ) i++;
      }
      else
      {
        // < single note >
        playTone(startNote, MSpN);
      }
    }
  }
  
//  Serial.println(":::::::: score end :::::::::");
}
// set octave's min and max
int getValidOctave( int val )
{
  if( val < -2 ) val = -2;
  if( 4 < val ) val = 4;
  return val;
}


// ----------------------------------------------------------------------------
// SCORE DATA 

// *Set score here.
char score1[] = "C--D--E----D--C--    C--D--E--D--C--D----.[>]C--D--E----D--C--    C--D--E--D--C--D----.";
char score2[] = "[<<]CDEFGAB[>]CDEFGAB[>]CDEFGAB[>]CDEFGAB[>]CDEFGAB[>]CDEFGAB[>]CDEFGAB.";
char score3[] = "E(<<)A~G(>)BB(<<)B(>)~~BF(>>>>)E(<)D D(<)AB B";
char score4[] = "[<<],E--E~~D[>>]F(<)--F--F--  ,[<<<<],E--E~~D[>>]F(<)--F--F-- E,[<<<<],E--E~~D[>>>>]F(<)--F--F--E~_E(<),[<<<<],E--E~~D[>>>>]F(<)--F--F-- E(>)";

// ----------------------------------------------------------------------------
// MAIN

void setup() 
{
//  Serial.begin(9600);
  pinMode(SPEAKER_PIN, OUTPUT);
  pinMode(SW_PIN_1, INPUT);
  pinMode(SW_PIN_2, INPUT);
  pinMode(SW_PIN_3, INPUT);
  pinMode(SW_PIN_4, INPUT);
}

void loop() 
{
  // switches
  if(digitalRead(SW_PIN_1))      playScore(score1);
  else if(digitalRead(SW_PIN_2)) playScore(score2);
  else if(digitalRead(SW_PIN_3)) playScore(score3,100); // *** If you want to change time per note, set 2nd argument here  with milliseconds.
  else if(digitalRead(SW_PIN_4)) playScore(score4,100);
}

