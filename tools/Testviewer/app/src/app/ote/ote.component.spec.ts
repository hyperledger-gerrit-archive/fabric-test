import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { OTEComponent } from './ote.component';

describe('OTEComponent', () => {
  let component: OTEComponent;
  let fixture: ComponentFixture<OTEComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ OTEComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OTEComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
