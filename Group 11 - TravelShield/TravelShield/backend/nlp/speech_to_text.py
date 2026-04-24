import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
import speech_recognition as sr
import os


def record_audio_enter_to_stop(filename="temp.wav", fs=16000):
    """
    Records audio until user presses ENTER.
    Saves the recording as a WAV file.
    """

    print("\n🎤 Recording started... Speak now!")
    print("➡️ Press ENTER when you finish speaking.\n")

    audio_frames = []

    def callback(indata, frames, time, status):
        if status:
            print("Audio status:", status)
        audio_frames.append(indata.copy())

    stream = sd.InputStream(
        samplerate=fs,
        channels=1,
        dtype=np.int16,
        callback=callback
    )

    stream.start()
    input()  # wait for ENTER
    stream.stop()
    stream.close()

    audio_data = np.concatenate(audio_frames, axis=0)
    wav.write(filename, fs, audio_data)

    print("✅ Recording saved.\n")
    return filename


def speech_to_text(language_choice):
    """
    Converts speech to text based on user-selected language.

    language_choice:
    - "ml" → Malayalam speech recognition
    - "en" → English speech recognition
    """

    audio_file = record_audio_enter_to_stop()

    recognizer = sr.Recognizer()
    recognizer.dynamic_energy_threshold = True

    with sr.AudioFile(audio_file) as source:
        audio_data = recognizer.record(source)

    # Select language model
    lang_code = "ml-IN" if language_choice == "ml" else "en-IN"

    try:
        text = recognizer.recognize_google(audio_data, language=lang_code)
    except:
        text = None

    # Cleanup
    if os.path.exists(audio_file):
        os.remove(audio_file)

    return text
