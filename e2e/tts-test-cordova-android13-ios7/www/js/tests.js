let testResults = [];
const results = document.getElementById('results');
const status = document.getElementById('status');

function log(message, type = 'info') {
    const div = document.createElement('div');
    div.className = `test ${type}`;
    div.textContent = message;
    results.appendChild(div);
    console.log(`[${type}] ${message}`);
}

async function test(name, fn) {
    const startTime = Date.now();
    log(`Running: ${name}`, 'running');
    console.log(`TEST_RUNNING::${name}`);
    
    try {
        await fn();
        const duration = Date.now() - startTime;
        log(`✓ PASS: ${name}`, 'pass');
        console.log(`TEST_RESULT::${name}::PASS::${duration}ms`);
        testResults.push({name, passed: true, duration});
        return true;
    } catch (err) {
        const duration = Date.now() - startTime;
        log(`✗ FAIL: ${name} - ${err.message}`, 'fail');
        console.log(`TEST_RESULT::${name}::FAIL::${duration}ms::${err.message}`);
        testResults.push({name, passed: false, error: err.message, duration});
        return false;
    }
}

async function runTests() {
    results.innerHTML = '';
    testResults = [];
    status.textContent = 'Running tests...';
    
    console.log('TEST_START');
    console.log(`TEST_PLATFORM::${cordova.platformId}`);
    const testSuiteStart = Date.now();

    // Test 1: TTS is available
    await test('TTS plugin is available', async () => {
        if (!window.TTS) throw new Error('window.TTS not defined');
    });

    // Test 2: Speak short text
    await test('Speak short text completes', async () => {
        await TTS.speak({text: 'test', rate: 2.0, cancel: true});
    });

    // Test 3: Speak empty string
    await test('Speak empty string completes', async () => {
        await TTS.speak({text: '', cancel: true});
    });

    // Test 4: Stop when not speaking
    await test('Stop when idle succeeds', async () => {
        await TTS.stop();
    });

    // Test 5: Stop during speech
    await test('Stop interrupts speech', async () => {
        const speakPromise = TTS.speak({
            text: 'This is a very long sentence that will be interrupted',
            rate: 0.5,
            cancel: true
        });
        
        // Wait a bit then stop
        await new Promise(r => setTimeout(r, 500));
        await TTS.stop();
        
        // Original speak promise should settle (either resolve or reject is ok)
        try {
            await speakPromise;
        } catch (e) {
            // Expected - speak was cancelled
        }
    });

    // Test 6: Sequential speaks
    await test('Sequential speaks work', async () => {
        await TTS.speak({text: 'one', rate: 2.0, cancel: true});
        await TTS.speak({text: 'two', rate: 2.0, cancel: true});
    });

    // Test 7: Cancel interrupts previous
    await test('Cancel=true interrupts previous speech', async () => {
        const first = TTS.speak({
            text: 'This should be cancelled',
            rate: 0.5,
            cancel: false
        });
        
        await new Promise(r => setTimeout(r, 200));
        
        const second = TTS.speak({
            text: 'quick',
            rate: 2.0,
            cancel: true
        });
        
        await second;
        // First may resolve or reject, both are acceptable
        try { await first; } catch(e) {}
    });

    // Test 8: Check language available
    await test('checkLanguage returns languages', async () => {
        const langs = await TTS.checkLanguage();
        if (!langs || langs.length === 0) {
            throw new Error('No languages returned');
        }
    });

    // Summary
    const testSuiteDuration = Date.now() - testSuiteStart;
    const passed = testResults.filter(r => r.passed).length;
    const total = testResults.length;
    const allPassed = passed === total;
    
    status.textContent = `Tests complete: ${passed}/${total} passed`;
    log(`\n=== SUMMARY: ${passed}/${total} tests passed ===`, 
        allPassed ? 'pass' : 'fail');
    
    // Parseable console output for automation
    console.log(`TEST_SUMMARY::${passed}/${total} passed::${allPassed ? 'SUCCESS' : 'FAILURE'}::${testSuiteDuration}ms`);
    console.log('TEST_COMPLETE');
    
    return allPassed;
}

async function testSpeak() {
    try {
        status.textContent = 'Speaking...';
        await TTS.speak({
            text: 'Hello, this is a test of the text to speech plugin.',
            locale: 'en-US',
            rate: 1.0,
            cancel: true
        });
        status.textContent = 'Speech completed';
    } catch (err) {
        status.textContent = `Error: ${err.message}`;
        console.error(err);
    }
}

document.addEventListener('deviceready', () => {
    status.textContent = 'Device ready - click Run Tests';
    log('Device ready', 'pass');
    log(`TTS available: ${!!window.TTS}`, window.TTS ? 'pass' : 'fail');
    
    document.getElementById('runTests').addEventListener('click', runTests);
    document.getElementById('testSpeak').addEventListener('click', testSpeak);
});
