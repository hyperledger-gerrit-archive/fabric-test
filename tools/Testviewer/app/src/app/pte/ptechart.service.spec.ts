import { TestBed, inject } from '@angular/core/testing';

import { PtechartService } from './ptechart.service';

describe('PtechartService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [PtechartService]
    });
  });

  it('should be created', inject([PtechartService], (service: PtechartService) => {
    expect(service).toBeTruthy();
  }));
});
