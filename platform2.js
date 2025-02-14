fileNames.forEach(fileName => { 
  document.write(`<a href="../$romfolder/${fileName}.bin" target="main"><figure><img loading="lazy" src="https://raw.githubusercontent.com/WizzardSK/${rom[2]// /_}/master/Named_Snaps/${fileName}.png" alt="${fileName}"><figcaption>${fileName}</figcaption></figure></a>`);
});
