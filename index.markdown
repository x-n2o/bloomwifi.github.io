---
layout: default
title: Bloom Nine Elms Guest Wi-Fi
west_password: "KwkY6N4K"
east_password: "6NHTtwFN"
---

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">

<style>
.building {
  margin-bottom: 2rem;
}
.building h2 {
  color: #333;
}
.pw {
  cursor: pointer;
  color: #007bff;
  font-size: 2rem;
  font-weight: bold;
  margin: 0.25rem 0;
}
.pw:hover {
  color: #0056b3;
}
.pw i {
  margin-left: 8px;
  font-size: 0.8em;
}
.qr-code {
  max-width: 300px;
  display: block;
}
</style>

<div class="building">
  <h2>Bloom West</h2>
  <p id="pw-west" class="pw" onclick="copyPw('pw-west', '{{ page.west_password }}')">{{ page.west_password }} <i class="fas fa-copy"></i></p>
  {% qr WIFI:T:WPA;S:Bloom Guest;P:{{ page.west_password }}; %}
</div>

<div class="building">
  <h2>Bloom East</h2>
  <p id="pw-east" class="pw" onclick="copyPw('pw-east', '{{ page.east_password }}')">{{ page.east_password }} <i class="fas fa-copy"></i></p>
  {% qr WIFI:T:WPA;S:Bloom Guest;P:{{ page.east_password }}; %}
</div>

<script>
function copyPw(id, password) {
  navigator.clipboard.writeText(password);
  const el = document.getElementById(id);
  const original = el.innerHTML;
  el.innerHTML = password + ' <i class="fas fa-check"></i>';
  el.style.color = '#28a745';
  setTimeout(() => {
    el.innerHTML = original;
    el.style.color = '#007bff';
  }, 2000);
}
</script>

<footer aria-label="Project resources">
  <p><a href="https://github.com/x-n2o/bloomwifi.github.io">GitHub</a></p>
</footer>
