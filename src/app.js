"use strict";

var Vue = require("vue/dist/vue.js");
var VueResource = require("vue-resource");
Vue.use(VueResource);
// var Plotly = require("plotly.js");
var Chart = require("chart.js");

var ENDPOINT = "http://127.0.0.1:8000/identify"

window.addEventListener("load", runApp);

Chart.defaults.global.defaultFontColor = "#222"
Chart.defaults.global.defaultFontFamily = "Source Sans Pro"
Chart.defaults.global.defaultFontSize = 12

function runApp() {
    var app = new Vue({
        el: "#app",
        data: {
            inputText: "",
            articlesChart: null,
            languagesChart: null,
            language: null
        },
        filters: {
            percentage: function (value) {
                var val = 100*value;
                return val.toPrecision(3);
            }
        },
        methods: {
            identify: function () {
                this.$http.post(ENDPOINT, this.inputText).then(this.identifyCallback, this.identifyErrback);
            },

            identifyCallback: function (response) {
                var results = JSON.parse(response.body);

                var languagesData = this.getData(results.languages);
                var articlesData = this.getData(results.articles);
                this.language = languagesData.languages[0];

                if (this.languagesChart === null) {
                    this.languagesChart = this.createBarPlot(languagesData,
                        "Most similar languages", this.$refs.languagesCanvas);
                }
                else {
                    this.updateBarPlot(languagesData, this.languagesChart);
                }
                if (this.articlesChart === null) {
                    this.articlesChart = this.createBarPlot(articlesData,
                        "Most similar articles", this.$refs.articlesCanvas);
                }
                else {
                    this.updateBarPlot(articlesData, this.articlesChart);
                }
            },

            identifyErrback: function (response) {
                console.log("Error in identifying language!");
                console.log(response);
            },

            getData: function (data) {
                var languages = [];
                var similarities = [];
                for (var i in data) {
                    languages.push(data[i].language);
                    similarities.push(data[i].similarity*100);
                }
                return {
                    languages: languages,
                    similarities: similarities
                }
            },

            createBarPlot: function (data, title, ctx) {
                ctx.width = 500;
                ctx.height = 400;
                ctx.style.display = "inline-block";
                return new Chart(ctx, {
                    type: "horizontalBar",
                    options: {
                        title: {
                            display: true,
                            text: title,
                            fontSize: 20
                        },
                        responsive: false
                    },
                    data: {
                        labels: data.languages,
                        datasets: [{
                            label: "Similarity (%)",
                            fill: true,
                            backgroundColor: "rgba(25,85,115,0.8)",
                            data: data.similarities
                        }]
                    }
                });
            },

            updateBarPlot: function (data, chartObj) {
                chartObj.data.labels = data.languages;
                chartObj.data.datasets[0].data = data.similarities;
                chartObj.update();
            }
        }
    });
}
