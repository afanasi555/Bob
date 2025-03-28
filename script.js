// Общие переменные
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
if (document.getElementById('audioInput')) {
    document.getElementById('audioInput').addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (file) {
            // Эмуляция разделения (замените на реальную обработку)
            const audioUrl = URL.createObjectURL(file);
            vocalBlob = file; // Здесь должна быть реальная обработка
            instrBlob = file; // Здесь должна быть реальная обработка
            document.getElementById('vocalPreview').src = audioUrl;
            document.getElementById('instrPreview').src = audioUrl;
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
        mixBlob = new Blob([vocalBlob, instrBlob]); // Эмуляция
        document.getElementById('mixPreview').src = URL.createObjectURL(mixBlob);
        document.getElementById('result').style.display = 'block';
        localStorage.removeItem('vocalToMix');
        localStorage.removeItem('instrToMix');
    }

    input1.addEventListener('change', updateMix);
    input2.addEventListener('change', updateMix);
    balance.addEventListener('input', updateMix);

    function updateMix() {
        if (input1.files[0] && input2.files[0]) {
            mixBlob = new Blob([input1.files[0], input2.files[0]]); // Эмуляция
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
    document.getElementById('audioInput').addEventListener('change', function(e) {
        const file = e.target.files[0];
        const format = document.getElementById('formatSelect').value;
        if (file) {
            convertedBlob = file; // Эмуляция
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
        editedBlob = new Blob([vocalBlob]); // Эмуляция
        document.getElementById('editedPreview').src = localStorage.getItem('vocalToEdit');
        document.getElementById('result').style.display = 'block';
        localStorage.removeItem('vocalToEdit');
        document.getElementById('result').innerHTML += '<button onclick="saveEditedVocal()">Сохранить вокал</button>';
    }

    input.addEventListener('change', updateEdit);
    document.querySelectorAll('.slider, .small-input').forEach(el => el.addEventListener('input', updateEdit));

    function updateEdit() {
        if (input.files[0]) {
            editedBlob = input.files[0]; // Эмуляция моментальной обработки
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
