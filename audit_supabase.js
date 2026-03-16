
const URL = 'https://zoaeypxhumpllhpasgun.supabase.co';
const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvYWV5cHhodW1wbGxocGFzZ3VuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTg2OTQ0MywiZXhwIjoyMDcxNDQ1NDQzfQ.YvUorZECgeLNGahHNfe4JfA1QODP3t5s1SEsebpxnR4';

async function finalCheck() {
    const resp = await fetch(`${URL}/rest/v1/profiles?select=*&limit=1`, {
        headers: { 'apikey': KEY, 'Authorization': `Bearer ${KEY}` }
    });
    if (resp.status === 200) {
        const data = await resp.json();
        if (data.length > 0) {
            const keys = Object.keys(data[0]);
            console.log(`Achievements exists: ${keys.includes('achievements')}`);
            console.log(`Hashtag in challenges: (checking next...)`);
        } else {
            console.log("Profiles empty, can't check cols via row.");
        }
    }

    const cResp = await fetch(`${URL}/rest/v1/challenges?select=*&limit=1`, {
        headers: { 'apikey': KEY, 'Authorization': `Bearer ${KEY}` }
    });
    if (cResp.status === 200) {
        const data = await cResp.json();
        if (data.length > 0) {
            console.log(`Hashtag exists in challenges: ${Object.keys(data[0]).includes('hashtag')}`);
        }
    }
}

finalCheck();
