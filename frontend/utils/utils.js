
export const anon = "./assets/anon.png"

export function parseTwitterDate(tdate) {
    var system_date = new Date(tdate)
    var user_date = new Date()

    var diff = Math.floor((Number(user_date) - Number(system_date)) / 1000)
    if (diff <= 1) {
      return "now"
    }
    if (diff < 60) {
      return diff + "s"
    }
    if (diff <= 90) {
      return "1m"
    }
    if (diff <= 3540) {
      return Math.round(diff / 60) + "m"
    }
    if (diff <= 5400) {
      return "1h"
    }
    if (diff <= 86400) {
      return Math.round(diff / 3600) + "h"
    }
    if (diff <= 129600) {
      return "1d"
    }
    if (diff < 604800) {
      return Math.round(diff / 86400) + "d"
    }
    if (diff <= 777600) {
      return "1w"
    }
    let month = system_date.getUTCMonth() + 1; //months from 1-12
    let day = system_date.getUTCDate();
    let year = system_date.getUTCFullYear();
    let newdate = day + "/" + month + "/" + year % 100;
    return newdate
  }

  export function urlify(text) {
    var urlRegex = /(https?:\/\/[^\s]+)/g;
    return text.replace(urlRegex, function(url) {
      return '<a class="post-url" href="' + url + '" target="_blank">' + url.slice(8, Math.min(url.length, 32)) + '...' + '</a>';
    })
  }

export function uniqBy(a, key) {
    return [
        ...new Map(
            a.map(x => [key(x), x])
        ).values()
    ]
}

export function textAreaAdjust(element) {
  element.style.height = "1px";
  element.style.height = (25+element.scrollHeight)+"px";
}

export const splitCamelCaseToString = (s) => {
  return s
    .split(/(?=[A-Z])/)
    .map((p) => {
      return p[0].toUpperCase() + p.slice(1)
    })
    .join(" ")
}

export async function resizeImage(imgToResize, targetSize = 400) {
  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d");

  const originalWidth = imgToResize.width;
  const originalHeight = imgToResize.height;

  let factor = 1.0
  if (originalWidth > targetSize) {
    factor = targetSize / originalWidth
  }

  const canvasWidth = originalWidth * factor;
  const canvasHeight = originalHeight * factor;

  canvas.width = canvasWidth;
  canvas.height = canvasHeight;

  context.drawImage(
    imgToResize,
    0,
    0,
    originalWidth * factor,
    originalHeight * factor
  );

  const blob = await new Promise(resolve => canvas.toBlob(resolve));
  return blob
}