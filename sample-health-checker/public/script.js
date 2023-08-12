async function fetchData() {
  const haproxy_public_ip = document.getElementById('haproxy_public_ip').value;
  const response = await fetch(`http://${haproxy_public_ip}`, {
    method: 'GET',
    headers: {
      'Cache-Control': 'no-cache'
    }
  });
  const data = await response.text();

  let lines = data.split('\n');
  let resultIndex = lines.findIndex(e => e.includes("Serving from"));

  let str;
  if (resultIndex === -1) {
    str = "No matches found";
  } else {
    str = lines.slice(resultIndex).join('\n').replace(/<[^>]+>/g, ' ');
  }

  const listItem = document.createElement('li');
  listItem.textContent = str;
  document.getElementById('resultList').appendChild(listItem);
}

// Call fetchData every 5 seconds
setInterval(fetchData, 5000);
