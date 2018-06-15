import { Component, OnInit, ViewChild } from '@angular/core';
import { serverurl } from '../serveraction';
import { DateselectService } from '../main/dateselect.service'
import { CoveragechartService } from './coveragechart.service'

@Component({
  selector: 'app-coverage',
  templateUrl: './coverage.component.html',
  styleUrls: ['./coverage.component.css']
})
export class CoverageComponent implements OnInit {

  constructor(private dateselectService:DateselectService, private coveragechartService:CoveragechartService) { }

  @ViewChild('dateinput_master') dateinput_master;
  @ViewChild('dateinput_1dot1') dateinput_1dot1;
  @ViewChild('startdateinput_master') startdateinput_master;
  @ViewChild('enddateinput_master') enddateinput_master;
  @ViewChild('startdateinput_1dot1') startdateinput_1dot1;
  @ViewChild('enddateinput_1dot1') enddateinput_1dot1;

  id_master = 'coveragechart_master';
  id_1dot1 = 'coveragechart_1dot1';
  width = "100%";
  height = "600";
  type = 'msline';
  dataFormat = 'json';
  dataSource_master;
  dataSource_1dot1;

  buildnum = {
  	'master':null,
  	'1dot1':null
  };
  chosendate = {
  	'master':null,
  	'1dot1':null
  };
  objectkeys = Object.keys
  prjcts = {
  	'master':{},
  	'1dot1':{}
  }

  getBuildHistory(project) {
  	fetch(`${serverurl}/cov-history/${project}`, {method:'GET'})
  	.then(res => res.json())
  	.then(res => {
  		
  	})
  }

  updateChosenDate(date, project) {
    this.chosendate[project] = this.dateselectService.convertDateFormat(date)
    fetch(`${serverurl}/covbuild/${project}/${this.chosendate[project]}` ,{
       method:'GET',
     })
    .then(res => res.json())
    .then(res => {
      this.buildnum[project] = res['build']
    })
  }

  initCoverageObj(obj) {
  	obj['name'] = null
  	obj['packages'] = null
  	obj['files'] = null
  	obj['classes'] = null
  	obj['methods'] = null
  	obj['lines'] = null
  	obj['conditionals'] = null
  }

  getData(id, date) {
  	fetch(`${serverurl}/coverage/${id}/${this.dateselectService.convertDateFormat(date)}`,{method:"GET"})
  	.then(res => res.json())
  	.then(res => {
		this.prjcts[id]['name'] = typeof res.name == "string" ? res.name.replace("dot","."): res.name
  		this.prjcts[id]['packages'] = res.Packages
  		this.prjcts[id]['files'] = res.Files
  		this.prjcts[id]['classes'] = res.Classes
  		this.prjcts[id]['methods'] = res.Methods
  		this.prjcts[id]['lines'] = res.Lines
  		this.prjcts[id]['conditionals'] = res.Conditionals
  	})
  }

  loadAllData() {
  	this.getData('master', this.dateinput_master.nativeElement.value)
  	this.getData('1dot1', this.dateinput_1dot1.nativeElement.value)
  	this.updateChosenDate(this.dateinput_master.nativeElement.value, 'master')
  	this.updateChosenDate(this.dateinput_1dot1.nativeElement.value, '1dot1')
  }

  loadMasterChart(startdate, enddate) {
  	this.coveragechartService.loadLineChart(startdate, enddate, 'master')
  	.then(line => {
  		for (let data of line.dataset) {
	        for (let datapoint of data.data) {
	          datapoint.value = parseFloat(datapoint.value).toFixed(2)
	        }
	    }
  		this.dataSource_master = line;
  	})
  }

  load1dot1Chart(startdate, enddate) {
  	this.coveragechartService.loadLineChart(startdate, enddate, '1dot1')
  	.then(line => {
  		for (let data of line.dataset) {
	        for (let datapoint of data.data) {
	          datapoint.value = parseFloat(datapoint.value).toFixed(2)
	        }
	    }
  		this.dataSource_1dot1 = line;
  	})
  }

  ngOnInit() {
  	let weekRange = this.dateselectService.weekRange()
  	this.startdateinput_master.nativeElement.value = weekRange[0]
  	this.startdateinput_1dot1.nativeElement.value = weekRange[0]
  	this.enddateinput_master.nativeElement.value = weekRange[1]
  	this.enddateinput_1dot1.nativeElement.value = weekRange[1]
  	this.dateinput_master.nativeElement.value = this.dateselectService.getToday()
  	this.dateinput_1dot1.nativeElement.value = this.dateselectService.getToday()
  	for (let obj of Object.keys(this.prjcts)) {
  		this.initCoverageObj(this.prjcts[obj])
  	}
  	this.loadAllData()
  	this.dateselectService.checkEndDate(`${serverurl}/coverage/master/${this.dateselectService.convertDateFormat(weekRange[1])}`)
    .then(bool => {
      if (bool == true) {
        this.loadMasterChart(this.startdateinput_master.nativeElement.value, this.enddateinput_master.nativeElement.value)  
      }
      else {
        let lastday = new Date(weekRange[1])
        let prevday = new Date(lastday.setDate(lastday.getDate() - 1))
        this.enddateinput_master.nativeElement.value = [prevday.getMonth()+1, prevday.getDate(), prevday.getFullYear()].join('/')
        this.loadMasterChart(this.startdateinput_master.nativeElement.value, this.enddateinput_master.nativeElement.value)  
      }
    })
    this.dateselectService.checkEndDate(`${serverurl}/coverage/1dot1/${this.dateselectService.convertDateFormat(weekRange[1])}`)
    .then(bool => {
      if (bool == true) {
        this.load1dot1Chart(this.startdateinput_1dot1.nativeElement.value, this.enddateinput_1dot1.nativeElement.value)  
      }
      else {
        let lastday = new Date(weekRange[1])
        let prevday = new Date(lastday.setDate(lastday.getDate() - 1))
        this.enddateinput_1dot1.nativeElement.value = [prevday.getMonth()+1, prevday.getDate(), prevday.getFullYear()].join('/')
        this.load1dot1Chart(this.startdateinput_1dot1.nativeElement.value, this.enddateinput_1dot1.nativeElement.value)  
      }
    })
  }

}
