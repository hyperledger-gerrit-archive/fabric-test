import { TestBed, inject } from '@angular/core/testing';

import { DateselectService } from './dateselect.service';

describe('DateselectService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [DateselectService]
    });
  });

  it('should be created', inject([DateselectService], (service: DateselectService) => {
    expect(service).toBeTruthy();
  }));
});
