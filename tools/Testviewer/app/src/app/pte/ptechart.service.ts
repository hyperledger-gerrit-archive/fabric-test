import { Injectable } from '@angular/core';
import { serverurl } from '../serveraction';
import { DateselectService } from '../main/dateselect.service'


@Injectable({
  providedIn: 'root'
})
export class PtechartService {

  constructor( private dateselectService: DateselectService) { }

  sortBySeriesName(dataset) {
  	return dataset.sort(function(a,b) {return a.seriesname < b.seriesname ? -1 : 1})
  }

  loadLineChart(startdate, enddate, tests) {
  	/*
	Loads line chart
  	*/
  	//// Calculate categories i.e. dates for x-axis
    let categories = this.dateselectService.getDateCategories(startdate, enddate)
    //// Gets dataset for plotting
    let dataset_invoke = [],
    	dataset_query = [],
    	differentialdataset_invoke = [],
    	differentialdataset_query = [],
   		dataSourceArray;
    for (let fabnum of tests) {
      let promisearray = [],
      	  data_pte_invoke = [],
      	  data_pte_query = [];
      // Fills promisearray with fetch of each date in category for current fabnum
      for (let category of categories) {
        promisearray.push(
        	fetch(`${serverurl}/pte/${fabnum}/${category["label"]}` ,{method:'GET'})
	        .then(res => res.json())
	        .then(res => {
	          data_pte_invoke.push({
	            "value":res['invoke']['tps'],
	            "date":new Date(category["label"])
	          })
	          data_pte_query.push({
	            "value":res['query']['tps'],
	            "date":new Date(category["label"])
	          })
	        })
        )
      }
      // When all promises are resolved, push this fab's data to dataset (i.e. 1 line in chart is being added to the rest)
      dataSourceArray = 
      	Promise.all(promisearray)
	      .then((_) => {

	      	let invoke_avg = this.dateselectService.getStat(data_pte_invoke)
	      	let query_avg = this.dateselectService.getStat(data_pte_query)
	      	let data_pte_invoke_sorted = data_pte_invoke.sort(function(a,b) {return a.date.getTime()-b.date.getTime();})
	      	let data_pte_query_sorted = data_pte_query.sort(function(a,b) {return a.date.getTime()-b.date.getTime();})

	        dataset_invoke.push({
	          "seriesname":`${fabnum} (Avg ${invoke_avg})`,
	          "data":data_pte_invoke_sorted
	        })
	        dataset_query.push({
	          "seriesname":`${fabnum} (Avg ${query_avg})`,
	          "data":data_pte_query_sorted
	        })


	        //// Make differential chart data using the regular data
	        let differentialdata_pte_invoke = [],
	        	differentialdata_pte_query = [];
	        for (let datapoint of data_pte_invoke_sorted) {
	        	differentialdata_pte_invoke.push({
	        		"value":100*(parseFloat(datapoint.value) - parseFloat(invoke_avg))/parseFloat(invoke_avg),
	        		"date":datapoint.date
	        	})
	        }
	        for (let datapoint of data_pte_query_sorted) {
	        	differentialdata_pte_query.push({
	        		"value":100*(parseFloat(datapoint.value) - parseFloat(query_avg))/parseFloat(query_avg),
	        		"date":datapoint.date
	        	})
	        }
	        differentialdataset_invoke.push({
	        	"seriesname":`${fabnum} (Avg ${invoke_avg})`,
	        	"data":differentialdata_pte_invoke
	        })
	        differentialdataset_query.push({
	        	"seriesname":`${fabnum} (Avg ${query_avg})`,
	        	"data":differentialdata_pte_query
	        })


	        // Sorting dataset keeps order of tests consistent. The way it's written, whole dataset is re-sorted
	        // every time new data is pushed
	        dataset_invoke = this.sortBySeriesName(dataset_invoke)
	        dataset_query = this.sortBySeriesName(dataset_query)

	        let dataSource_invoke_line = {
	            "chart": {
	                "caption": "PTE Invoke Metrics",
	                "subCaption": "TPS",
	                "numberprefix": "",
	                "theme": "fint",
	                "baseFontSize": "12",
	                "yaxisname":"TPS"
	            },
	            "categories":[
	              {"category":categories}
	            ],
	            "dataset": dataset_invoke
	        }
	        let dataSource_query_line = {
	            "chart": {
	                "caption": "PTE Query Metrics",
	                "subCaption": "TPS",
	                "numberprefix": "",
	                "theme": "fint",
	                "baseFontSize": "12",
	                "yaxisname":"TPS"
	            },
	            "categories":[
	              {"category":categories}
	            ],
	            "dataset": dataset_query
	        }
	        let dataSource_differentialinvoke_line = {
	        	"chart": {
	                "caption": "PTE Invoke Differential",
	                "subCaption": "Percentage Difference from Average",
	                "numbersuffix": "%",
	                "theme": "fint",
	                "baseFontSize": "12",
	                "yaxisname":"Percentage %"
	            },
	            "categories":[
	              {"category":categories}
	            ],
	            "dataset": differentialdataset_invoke
	        }
	        let dataSource_differentialquery_line = {
	        	"chart": {
	                "caption": "PTE Query Differential",
	                "subCaption": "Percentage Difference from Average",
	                "numbersuffix": "%",
	                "theme": "fint",
	                "baseFontSize": "12",
	                "yaxisname":"Percentage %"
	            },
	            "categories":[
	              {"category":categories}
	            ],
	            "dataset": differentialdataset_query
	        }

	        return [dataSource_invoke_line, dataSource_query_line, dataSource_differentialinvoke_line, dataSource_differentialquery_line]
	      })
    }
    return dataSourceArray
  }


}
