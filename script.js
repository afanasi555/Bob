let pyodide;
let vocalBlob, instrBlob, mixBlob, convertedBlob, editedBlob;
let editedVocalBlob = null;

async function loadPyodideAndPackages() {
    document.getElementById('progressText').textContent = 'Прогресс: 0% - Загрузка Pyodide';
    pyodide = await loadPyodide();
    document.getElementById('progressText').textContent = 'Прогресс: 10% - Установка библиотек';
    await pyodide.loadPackage(['numpy', 'scipy', 'micropip']);
    await pyodide.runPythonAsync(`
        import micropip
        await micropip.install('pydub')
        await micropip.install('soundfile')
        await micropip.install('ffmpeg-python')
    `);
    document.getElementById('progressText').textContent = 'Прогресс: 20% - Pyodide готов';
}

function syncSlidersAndInputs(sliderId, inputId) {
    const slider = document.getElementById(sliderId);
    const input = document.getElementById(inputId);
    slider.oninput = () => input.value = slider.value;
    input.oninput = () => slider.value = input.value;
}

function enableProcessButton() {
    const processButton = document.getElementById('processButton');
    if (document.getElementById('audioInput') && document.getElementById('audioInput').files.length > 0) {
        processButton.disabled = false;
    } else if (document.getElementById('audioInput1') && document.getElementById('audioInput1').files.length > 0 && 
               document.getElementById('audioInput2') && document.getElementById('audioInput2').files.length > 0) {
        processButton.disabled = false;
    } else {
        processButton.disabled = true;
    }
}

// Разделение аудио (MP3 и улучшенное разделение)
if (document.getElementById('audioInput') && !document.getElementById('speedSlider')) {
    document.getElementById('audioInput').addEventListener('change', enableProcessButton);
    document.getElementById('processButton').addEventListener('click', async () => {
        const file = document.getElementById('audioInput').files[0];
        if (file) {
            await loadPyodideAndPackages();
            document.getElementById('progressText').textContent = 'Прогресс: 30% - Чтение файла';
            const arrayBuffer = await file.arrayBuffer();
            const fileExt = file.name.split('.').pop().toLowerCase();
            pyodide.FS.writeFile(`input.${fileExt}`, new Uint8Array(arrayBuffer));
            document.getElementById('progressText').textContent = 'Прогресс: 40% - Конвертация в WAV';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                audio = AudioSegment.from_file('input.${fileExt}')
                audio.export('input.wav', format='wav')
            `);
            document.getElementById('progressText').textContent = 'Прогресс: 50% - Разделение';
            await pyodide.runPythonAsync(`
                import soundfile as sf
                import numpy as np
                from scipy import signal
                from scipy.fft import fft, ifft

                # Чтение аудио
                y, sr = sf.read('input.wav')
                if y.ndim > 1:
                    y = np.mean(y, axis=1)

                # Спектральный анализ
                n = len(y)
                freq = fft(y)
                freq_magnitude = np.abs(freq)
                freq_phase = np.angle(freq)

                # Фильтрация вокала (500 Гц - 4000 Гц) и инструментала
                freq_vocal = freq.copy()
                freq_instr = freq.copy()
                cutoff_low = 500 * n // sr
                cutoff_high = 4000 * n // sr
                freq_vocal[:cutoff_low] = 0
                freq_vocal[cutoff_high:n-cutoff_high] = 0
                freq_vocal[n-cutoff_low:] = 0
                freq_instr[cutoff_low:cutoff_high] = 0
                freq_instr[n-cutoff_high:n-cutoff_low] = 0

                # Обратное преобразование
                vocal = np.real(ifft(freq_vocal))
                instr = np.real(ifft(freq_instr))

                # Нормализация
                vocal = vocal / np.max(np.abs(vocal)) * 0.9
                instr = instr / np.max(np.abs(instr)) * 0.9

                # Сохранение
                sf.write('vocal.wav', vocal, sr)
                sf.write('instr.wav', instr, sr)
            `);
            document.getElementById('progressText').textContent = 'Прогресс: 100% - Готово';
            vocalBlob = new Blob([pyodide.FS.readFile('vocal.wav')], { type: 'audio/wav' });
            instrBlob = new Blob([pyodide.FS.readFile('instr.wav')], { type: 'audio/wav' });
            document.getElementById('vocalPreview').src = URL.createObjectURL(vocalBlob);
            document.getElementById('instrPreview').src = URL.createObjectURL(instrBlob);
            document.getElementById('result').style.display = 'block';
        }
    });
}

function editVocal() {
    localStorage.setItem('vocalToEdit', URL.createObjectURL(vocalBlob));
    window.location.href = 'editing.html?vocal=true';
}

function mixResults() {
    localStorage.setItem('vocalToMix', URL.createObjectURL(vocalBlob));
    localStorage.setItem('instrToMix', URL.createObjectURL(instrBlob));
    window.location.href = 'mixing.html?fromSeparation=true';
}

function playPreview(type) {
    const audio = document.getElementById(type === 'vocal' ? 'vocalPreview' : 'instrPreview');
    audio.play();
}

function downloadResults() {
    const includeOriginal = confirm('Включить оригинальный вокал в скачивание?');
    const zip = new JSZip();
    if (editedVocalBlob && !includeOriginal) {
        zip.file('vocal_edited.wav', editedVocalBlob);
    } else {
        zip.file('vocal.wav', vocalBlob);
        if (editedVocalBlob) zip.file('vocal_edited.wav', editedVocalBlob);
    }
    zip.file('instrumental.wav', instrBlob);
    zip.generateAsync({ type: 'blob' }).then(blob => {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = 'separated_audio.zip';
        link.click();
    });
}

// Смешивание аудио
if (document.getElementById('audioInput1')) {
    const input1 = document.getElementById('audioInput1');
    const input2 = document.getElementById('audioInput2');
    const balance = document.getElementById('mixBalance');

    input1.addEventListener('change', enableProcessButton);
    input2.addEventListener('change', enableProcessButton);

    if (localStorage.getItem('vocalToMix')) {
        input1.disabled = true;
        input2.disabled = true;
        document.getElementById('processButton').disabled = false;
    }

    document.getElementById('processButton').addEventListener('click', async () => {
        let file1 = input1.files[0];
        let file2 = input2.files[0];
        if (localStorage.getItem('vocalToMix')) {
            file1 = await fetch(localStorage.getItem('vocalToMix')).then(res => res.blob());
            file2 = await fetch(localStorage.getItem('instrToMix')).then(res => res.blob());
        }
        if (file1 && file2) {
            await loadPyodideAndPackages();
            document.getElementById('progressText').textContent = 'Прогресс: 30% - Чтение файлов';
            const arrayBuffer1 = await file1.arrayBuffer();
            const arrayBuffer2 = await file2.arrayBuffer();
            const ext1 = file1.name.split('.').pop().toLowerCase();
            const ext2 = file2.name.split('.').pop().toLowerCase();
            pyodide.FS.writeFile(`audio1.${ext1}`, new Uint8Array(arrayBuffer1));
            pyodide.FS.writeFile(`audio2.${ext2}`, new Uint8Array(arrayBuffer2));
            document.getElementById('progressText').textContent = 'Прогресс: 40% - Конвертация в WAV';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                audio1 = AudioSegment.from_file('audio1.${ext1}')
                audio2 = AudioSegment.from_file('audio2.${ext2}')
                audio1.export('audio1.wav', format='wav')
                audio2.export('audio2.wav', format='wav')
            `);
            document.getElementById('progressText').textContent = 'Прогресс: 50% - Смешивание';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                audio1 = AudioSegment.from_file('audio1.wav')
                audio2 = AudioSegment.from_file('audio2.wav')
                balance = ${balance.value}
                balance = (balance + 100) / 200
                audio1 = audio1 - (20 * (1 - balance))
                audio2 = audio2 - (20 * balance)
                mixed = audio1.overlay(audio2)
                mixed.export('mixed.wav', format='wav')
            `);
            document.getElementById('progressText').textContent = 'П References: 100% - Готово';
            mixBlob = new Blob([pyodide.FS.readFile('mixed.wav')], { type: 'audio/wav' });
            document.getElementById('mixPreview').src = URL.createObjectURL(mixBlob);
            document.getElementById('result').style.display = 'block';
            if (localStorage.getItem('vocalToMix')) {
                localStorage.removeItem('vocalToMix');
                localStorage.removeItem('instrToMix');
            }
        }
    });
}

function playMixPreview() {
    document.getElementById('mixPreview').play();
}

function downloadMix() {
    const onlyMixed = confirm('Скачать только смешанный файл?');
    if (onlyMixed) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(mixBlob);
        link.download = 'mixed_audio.wav';
        link.click();
    } else {
        const zip = new JSZip();
        zip.file('mixed.wav', mixBlob);
        zip.file('audio1.wav', document.getElementById('audioInput1').files[0]);
        zip.file('audio2.wav', document.getElementById('audioInput2').files[0]);
        zip.generateAsync({ type: 'blob' }).then(blob => {
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = 'mixed_audio.zip';
            link.click();
        });
    }
}

// Конвертация аудио
if (document.getElementById('sourceFormat')) {
    document.getElementById('audioInput').addEventListener('change', enableProcessButton);
    document.getElementById('processButton').addEventListener('click', async () => {
        const file = document.getElementById('audioInput').files[0];
        const sourceFormat = document.getElementById('sourceFormat').value;
        const targetFormat = document.getElementById('targetFormat').value;
        if (file) {
            await loadPyodideAndPackages();
            document.getElementById('progressText').textContent = 'Прогресс: 30% - Чтение файла';
            const arrayBuffer = await file.arrayBuffer();
            pyodide.FS.writeFile(`input.${sourceFormat}`, new Uint8Array(arrayBuffer));
            document.getElementById('progressText').textContent = 'Прогресс: 50% - Конвертация';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                audio = AudioSegment.from_file('input.${sourceFormat}', format='${sourceFormat}')
                audio.export('output.${targetFormat}', format='${targetFormat}')
            `);
            document.getElementById('progressText').textContent = 'Прогресс: 100% - Готово';
            convertedBlob = new Blob([pyodide.FS.readFile(`output.${targetFormat}`)], { type: `audio/${targetFormat}` });
            document.getElementById('convertedPreview').src = URL.createObjectURL(convertedBlob);
            document.getElementById('result').style.display = 'block';
        }
    });
}

function playConvertedPreview() {
    document.getElementById('convertedPreview').play();
}

function downloadConverted() {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(convertedBlob);
    link.download = `converted_audio.${document.getElementById('targetFormat').value}`;
    link.click();
}

// Изменение аудио
if (document.getElementById('speedSlider')) {
    syncSlidersAndInputs('speedSlider', 'speedInput');
    syncSlidersAndInputs('pitchSlider', 'pitchInput');
    syncSlidersAndInputs('echoSlider', 'echoInput');
    syncSlidersAndInputs('reverbSlider', 'reverbInput');
    syncSlidersAndInputs('flangerSlider', 'flangerInput');
    syncSlidersAndInputs('volumeSlider', 'volumeInput');

    const input = document.getElementById('audioInput');
    if (localStorage.getItem('vocalToEdit')) {
        input.disabled = true;
        document.getElementById('saveVocalBtn').style.display = 'inline-block';
        document.getElementById('processButton').disabled = false;
    }

    input.addEventListener('change', enableProcessButton);
    document.getElementById('processButton').addEventListener('click', async () => {
        const file = localStorage.getItem('vocalToEdit') ? await fetch(localStorage.getItem('vocalToEdit')).then(res => res.blob()) : input.files[0];
        if (file) {
            await loadPyodideAndPackages();
            document.getElementById('progressText').textContent = 'Прогресс: 30% - Чтение файла';
            const arrayBuffer = await file.arrayBuffer();
            const fileExt = file.name.split('.').pop().toLowerCase();
            pyodide.FS.writeFile(`input.${fileExt}`, new Uint8Array(arrayBuffer));
            document.getElementById('progressText').textContent = 'Прогресс: 40% - Конвертация в WAV';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                audio = AudioSegment.from_file('input.${fileExt}')
                audio.export('input.wav', format='wav')
            `);
            const speed = document.getElementById('speedInput').value;
            const pitch = document.getElementById('pitchInput').value;
            const echo = document.getElementById('echoInput').value;
            const reverb = document.getElementById('reverbInput').value;
            const flanger = document.getElementById('flangerInput').value;
            const volume = document.getElementById('volumeInput').value;
            document.getElementById('progressText').textContent = 'Прогресс: 50% - Применение эффектов';
            await pyodide.runPythonAsync(`
                from pydub import AudioSegment
                from pydub.effects import speedup
                import soundfile as sf
                import numpy as np
                from scipy.signal import convolve

                audio = AudioSegment.from_file('input.wav')
                if ${speed} != 1:
                    audio = speedup(audio, playback_speed=${speed})
                if ${pitch} != 0:
                    audio = audio._spawn(audio.raw_data, overrides={'frame_rate': int(audio.frame_rate * (2.0 ** (${pitch} / 12.0)))})
                if ${volume} != 0:
                    audio = audio + ${volume}
                if ${echo} > 0:
                    echo_audio = audio - 10 - ${echo / 100}
                    audio = audio.overlay(echo_audio)
                audio.export('temp.wav', format='wav')

                y, sr = sf.read('temp.wav')
                if y.ndim > 1:
                    y = np.mean(y, axis=1)
                if ${reverb} > 0 or ${flanger} > 0:
                    if ${reverb} > 0:
                        impulse = np.zeros(int(sr * 0.5))
                        impulse[0] = 1
                        decay = np.exp(-np.linspace(0, 5, len(impulse)))
                        impulse += decay * 0.1 * ${reverb / 100}
                        y = convolve(y, impulse, mode='full')[:len(y)]
                    if ${flanger} > 0:
                        delay = np.sin(2 * np.pi * ${flanger / 10} * np.arange(len(y)) / sr) * 0.01
                        delayed = np.interp(np.arange(len(y)) + delay * sr, np.arange(len(y)), y)
                        y = y + delayed * 0.5
                sf.write('edited.wav', y, sr)
            `);
            document.getElementById('progressText').textContent = 'Прогресс: 100% - Готово';
            editedBlob = new Blob([pyodide.FS.readFile('edited.wav')], { type: 'audio/wav' });
            document.getElementById('editedPreview').src = URL.createObjectURL(editedBlob);
            document.getElementById('result').style.display = 'block';
            if (localStorage.getItem('vocalToEdit')) {
                localStorage.removeItem('vocalToEdit');
            }
        }
    });
}

function playEditedPreview() {
    document.getElementById('editedPreview').play();
}

function downloadEdited() {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(editedBlob);
    link.download = 'edited_audio.wav';
    link.click();
}

function saveEditedVocal() {
    editedVocalBlob = editedBlob;
    window.location.href = 'separation.html';
}
