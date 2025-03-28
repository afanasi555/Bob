// URL сервера на Glitch
const SERVER_URL = 'https://d699b6f2-1143-4e86-a434-0a3d0803b2af-00-bln4qkwkaxad.kirk.replit.dev';

// Глобальные переменные
let vocalBlob, instrBlob, mixBlob, convertedBlob, editedBlob;
let editedVocalBlob = null;

// Синхронизация ползунков и полей ввода
function syncSlidersAndInputs(sliderId, inputId) {
    const slider = document.getElementById(sliderId);
    const input = document.getElementById(inputId);
    slider.oninput = () => input.value = slider.value;
    input.oninput = () => slider.value = input.value;
}

// Разделение аудио
if (document.getElementById('audioInput') && !document.getElementById('speedSlider')) {
    document.getElementById('audioInput').addEventListener('change', async function(e) {
        const file = e.target.files[0];
        if (file) {
            const formData = new FormData();
            formData.append('audio', file);
            const response = await fetch(`${SERVER_URL}/separate`, {
                method: 'POST',
                body: formData
            });
            const data = await response.json();
            vocalBlob = await fetch(data.vocal).then(res => res.blob());
            instrBlob = await fetch(data.instrumental).then(res => res.blob());
            document.getElementById('vocalPreview').src = URL.createObjectURL(vocalBlob);
            document.getElementById('instrPreview').src = URL.createObjectURL(instrBlob);
            document.getElementById('result').style.display = 'block';
        }
    });
}

// Изменение вокала
function editVocal() {
    localStorage.setItem('vocalToEdit', URL.createObjectURL(vocalBlob));
    window.location.href = 'editing.html?vocal=true';
}

// Смешивание результатов
function mixResults() {
    localStorage.setItem('vocalToMix', URL.createObjectURL(vocalBlob));
    localStorage.setItem('instrToMix', URL.createObjectURL(instrBlob));
    window.location.href = 'mixing.html?fromSeparation=true';
}

// Воспроизведение превью
function playPreview(type) {
    const audio = document.getElementById(type === 'vocal' ? 'vocalPreview' : 'instrPreview');
    audio.play();
}

// Скачивание результатов
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

    if (localStorage.getItem('vocalToMix')) {
        input1.disabled = true;
        input2.disabled = true;
        updateMix(vocalBlob, instrBlob);
        localStorage.removeItem('vocalToMix');
        localStorage.removeItem('instrToMix');
    }

    input1.addEventListener('change', () => updateMix(input1.files[0], input2.files[0]));
    input2.addEventListener('change', () => updateMix(input1.files[0], input2.files[0]));
    balance.addEventListener('input', () => updateMix(input1.files[0], input2.files[0]));

    async function updateMix(file1, file2) {
        if (file1 && file2) {
            const formData = new FormData();
            formData.append('audio1', file1);
            formData.append('audio2', file2);
            formData.append('balance', balance.value);
            const response = await fetch(`${SERVER_URL}/mix`, {
                method: 'POST',
                body: formData
            });
            mixBlob = await response.blob();
            document.getElementById('mixPreview').src = URL.createObjectURL(mixBlob);
            document.getElementById('result').style.display = 'block';
        }
    }
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
if (document.getElementById('formatSelect')) {
    document.getElementById('audioInput').addEventListener('change', async function(e) {
        const file = e.target.files[0];
        const format = document.getElementById('formatSelect').value;
        if (file) {
            const formData = new FormData();
            formData.append('audio', file);
            formData.append('format', format);
            const response = await fetch(`${SERVER_URL}/convert`, {
                method: 'POST',
                body: formData
            });
            convertedBlob = await response.blob();
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
    link.download = `converted_audio.${document.getElementById('formatSelect').value}`;
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
        updateEdit(localStorage.getItem('vocalToEdit'));
        localStorage.removeItem('vocalToEdit');
    }

    input.addEventListener('change', () => updateEdit(input.files[0]));
    document.querySelectorAll('.slider, .small-input').forEach(el => el.addEventListener('input', () => {
        if (input.files[0]) updateEdit(input.files[0]);
    }));

    async function updateEdit(fileOrUrl) {
        const file = typeof fileOrUrl === 'string' ? await fetch(fileOrUrl).then(res => res.blob()) : fileOrUrl;
        if (file) {
            const formData = new FormData();
            formData.append('audio', file);
            formData.append('speed', document.getElementById('speedInput').value);
            formData.append('pitch', document.getElementById('pitchInput').value);
            formData.append('echo', document.getElementById('echoInput').value);
            formData.append('reverb', document.getElementById('reverbInput').value);
            formData.append('flanger', document.getElementById('flangerInput').value);
            formData.append('volume', document.getElementById('volumeInput').value);
            const response = await fetch(`${SERVER_URL}/edit`, {
                method: 'POST',
                body: formData
            });
            editedBlob = await response.blob();
            document.getElementById('editedPreview').src = URL.createObjectURL(editedBlob);
            document.getElementById('result').style.display = 'block';
        }
    }
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
