import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PTEComponent } from './pte.component';

describe('PTEComponent', () => {
  let component: PTEComponent;
  let fixture: ComponentFixture<PTEComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PTEComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PTEComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
