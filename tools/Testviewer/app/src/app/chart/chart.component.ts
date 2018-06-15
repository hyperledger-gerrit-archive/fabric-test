import { Component, OnInit } from '@angular/core';
import { serverurl } from '../serveraction';

@Component({
  selector: 'app-chart',
  templateUrl: './chart.component.html',
  styleUrls: ['./chart.component.css']
})
export class ChartComponent implements OnInit {
	id = 'ptechart';
    width = 1000;
    height = 600;
    type = 'msline';
    dataFormat = 'json';
    dataSource;

  constructor() {
  }

  ngOnInit() {
  	let categories = []
  	for (let i = 0; i < 7; i++) {
  		let d = new Date();
  		d.setDate(d.getDate() - i);
  		categories.unshift({"label":[d.getFullYear(),("0" + (d.getMonth() + 1)).slice(-2), ("0" + d.getDate()).slice(-2)].join("-")});
  	}
  	let data_ote = []
  	let data_ptemove_3807 = []
  	let data_ptequery_3807 = []
  	let data_ptemove_3808 = []
  	let data_ptequery_3808 = []
  	for (let category of categories) {
  		fetch(`${serverurl}/ote/${category["label"]}` ,{
	       method:'GET',
	     })
  		.then(res => res.json())
  		.then(res => {
  			data_ote.push({
  				"value":res['tps'],
  				"date":category["label"]
  			})
  		})
  		fetch(`${serverurl}/pte/FAB-3807-4i/${category["label"]}` ,{
	       method:'GET',
	     })
  		.then(res => res.json())
  		.then(res => {
  			data_ptemove_3807.push({
  				"value":parseFloat(res['move']['tps']).toFixed(2),
  				"date":category["label"]
  			})
  			data_ptequery_3807.push({
  				"value":parseFloat(res['query']['tps']).toFixed(2),
  				"date":category["label"]
  			})
  		})
  		fetch(`${serverurl}/pte/FAB-3808-2i/${category["label"]}` ,{
	       method:'GET',
	     })
  		.then(res => res.json())
  		.then(res => {
  			data_ptemove_3808.push({
  				"value":parseFloat(res['move']['tps']).toFixed(2),
  				"date":category["label"]
  			})
  			data_ptequery_3808.push({
  				"value":parseFloat(res['query']['tps']).toFixed(2),
  				"date":category["label"]
  			})
  		})
  	}
  	this.dataSource = {
        "chart": {
            "caption": "Metrics",
            "subCaption": "TPS",
            "numberprefix": "",
            "theme": "fint"
        },
        "categories":[
        	{"category":categories}
        ],
        "dataset": [
		    {
		    	"seriesname":"OTE (FAB-6996)",
		    	"data":data_ote.sort(function(a,b) {
		    		return b.date-a.date;
		    	})
		    },
		    {
		    	"seriesname":"PTE Move (FAB-3807-4i)",
		    	"data":data_ptemove_3807.sort(function(a,b) {
		    		return b.date-a.date;
		    	})
		    },
		    {
		    	"seriesname":"PTE Query (FAB-3807-4i)",
		    	"data":data_ptequery_3807.sort(function(a,b) {
		    		return b.date-a.date;
		    	})
		    },
		    {
		    	"seriesname":"PTE Move (FAB-3808-2i)",
		    	"data":data_ptemove_3808.sort(function(a,b) {
		    		return b.date-a.date;
		    	})
		    },
		    {
		    	"seriesname":"PTE Query (FAB-3808-2i)",
		    	"data":data_ptequery_3808.sort(function(a,b) {
		    		return b.date-a.date;
		    	})
		    }
		]
    }
  }

}
