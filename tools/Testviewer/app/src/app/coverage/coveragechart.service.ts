import { Injectable } from '@angular/core';
import { serverurl } from '../serveraction';
import { DateselectService } from '../main/dateselect.service'

@Injectable({
  providedIn: 'root'
})
export class CoveragechartService {

  constructor(private dateselectService:DateselectService) { }

  loadLineChart(startdate, enddate, id) {
    let categories = []
    let currdate = new Date(enddate);
    while (currdate.getTime() >= new Date(startdate).getTime()) {
      categories.unshift({"label":[currdate.getFullYear(),("0" + (currdate.getMonth() + 1)).slice(-2), ("0" + currdate.getDate()).slice(-2)].join("-")});
      currdate.setDate(currdate.getDate()-1);
    }
    let dataset = []
    let dataSourceArray;
    for (let metric of ['Packages','Files','Classes','Methods','Lines','Conditionals']) {
		let data_cov = []
		let promisearray = []
		for (let category of categories) {
			promisearray.push(fetch(`${serverurl}/coverage/${id}/${category["label"]}` ,{method:'GET'})
			.then(res => res.json())
			.then(res => {
				data_cov.push({
					"value":eval(res[metric]) * 100,
					"date":new Date(category["label"])
				})
			})
		)}
		dataSourceArray = Promise.all(promisearray)
		.then((_) => {
			dataset.push({
			  "seriesname":`${metric} (Avg ${this.dateselectService.getStat(data_cov)})`,
			  "data":data_cov.sort(function(a,b) {
			    return a.date.getTime()-b.date.getTime();
			  })
			})
			let chartcaption = id.replace("dot",".")
			let dataSource_line = {
			    "chart": {
			        "caption": `${chartcaption} Coverage`,
			        "subCaption": "",
			        "numberprefix": "",
			        "theme": "fint",
			        "baseFontSize": "12",
			        "yaxisname":"% Coverage"
			    },
			    "categories":[
			      {"category":categories}
			    ],
			    "dataset": dataset
			}
			return dataSource_line
		})
	}
    return dataSourceArray
  }
}
